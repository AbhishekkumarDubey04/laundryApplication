import { Router, Response } from 'express';
import { query } from '../config/db';
import { AuthenticatedRequest, authenticateToken, authorizeRoles } from '../middleware/auth';

const router = Router();

// Helper to add days to a date string
const addDays = (dateStr: string, days: number): string => {
  const date = new Date(dateStr);
  date.setDate(date.getDate() + days);
  return date.toISOString().split('T')[0];
};

/**
 * POST /orders
 * Creates a new order for the authenticated customer
 */
router.post('/', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const {
    pickup_address_id,
    pickup_date,
    pickup_time_slot,
    delivery_preference,
    coupon_code,
    items // array of { item_id: number, service_id: number, quantity: number }
  } = req.body;

  if (!pickup_address_id || !pickup_date || !pickup_time_slot || !items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'Missing required booking details or item cart list' });
  }

  try {
    // 1. Calculate item costs
    let totalAmount = 0;
    const itemsWithPricing = [];

    for (const cartItem of items) {
      const { item_id, service_id, quantity } = cartItem;
      if (!item_id || !service_id || !quantity || quantity <= 0) {
        return res.status(400).json({ error: 'Invalid item quantity or services selected' });
      }

      // Fetch price from DB
      const rateResult = await query(
        'SELECT price FROM service_pricing WHERE service_id = $1 AND item_id = $2',
        [service_id, item_id]
      );

      if (rateResult.rows.length === 0) {
        return res.status(400).json({ error: `Pricing not found for item ID ${item_id} with service ID ${service_id}` });
      }

      const unitPrice = parseFloat(rateResult.rows[0].price);
      const itemTotalPrice = unitPrice * quantity;
      totalAmount += itemTotalPrice;

      itemsWithPricing.push({
        item_id,
        service_id,
        quantity,
        unit_price: unitPrice,
        total_price: itemTotalPrice
      });
    }

    // 2. Validate Coupon and calculate discount
    let discountAmount = 0.00;
    if (coupon_code) {
      const couponResult = await query(
        'SELECT * FROM coupons WHERE code = $1 AND expiry_date > NOW() AND status = \'active\'',
        [coupon_code]
      );

      if (couponResult.rows.length > 0) {
        const coupon = couponResult.rows[0];
        const minOrder = parseFloat(coupon.min_order_value);
        if (totalAmount >= minOrder) {
          const discountVal = parseFloat(coupon.discount_value);
          if (coupon.discount_type === 'flat') {
            discountAmount = Math.min(discountVal, totalAmount);
          } else if (coupon.discount_type === 'percentage') {
            discountAmount = parseFloat(((totalAmount * discountVal) / 100).toFixed(2));
          }
        }
      }
    }

    // 3. Delivery charges calculation
    let deliveryCharges = 30.00; // Base charge
    if (totalAmount - discountAmount >= 500.00) {
      deliveryCharges = 0.00; // Free delivery above 500 rupees
    }
    
    if (delivery_preference === 'express') {
      deliveryCharges += 50.00; // Extra for express
    } else if (delivery_preference === 'same_day') {
      deliveryCharges += 100.00; // Extra for same-day
    }

    // 4. GST tax calculation (18% standard India service tax)
    const taxableAmount = Math.max(0, totalAmount - discountAmount);
    const taxAmount = parseFloat((taxableAmount * 0.18).toFixed(2));

    // 5. Grand Total calculation
    const grandTotal = parseFloat((taxableAmount + deliveryCharges + taxAmount).toFixed(2));

    // 6. Estimate delivery date based on preference
    let deliveryDays = 3;
    if (delivery_preference === 'express') {
      deliveryDays = 1;
    } else if (delivery_preference === 'same_day') {
      deliveryDays = 0;
    }
    const estimatedDeliveryDate = addDays(pickup_date, deliveryDays);

    // 7. Insert Order record (Atomic transaction)
    await query('BEGIN');

    const orderInsertQuery = `
      INSERT INTO orders (
        user_id, pickup_address_id, pickup_date, pickup_time_slot, 
        delivery_preference, delivery_date, status, total_amount, 
        discount_amount, delivery_charges, tax_amount, grand_total, 
        coupon_code, payment_status
      ) VALUES ($1, $2, $3, $4, $5, $6, 'created', $7, $8, $9, $10, $11, $12, 'pending')
      RETURNING *;
    `;
    const orderParams = [
      req.user?.id,
      pickup_address_id,
      pickup_date,
      pickup_time_slot,
      delivery_preference,
      estimatedDeliveryDate,
      totalAmount,
      discountAmount,
      deliveryCharges,
      taxAmount,
      grandTotal,
      coupon_code || null
    ];
    
    const orderResult = await query(orderInsertQuery, orderParams);
    const createdOrder = orderResult.rows[0];

    // 8. Insert Order Items
    for (const item of itemsWithPricing) {
      await query(
        `INSERT INTO order_items (order_id, item_id, service_id, quantity, unit_price, total_price)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [createdOrder.id, item.item_id, item.service_id, item.quantity, item.unit_price, item.total_price]
      );
    }

    // 9. Create user notification
    const notificationTitle = 'Order Placed Successfully!';
    const notificationMsg = `Your laundry order #${createdOrder.id} is confirmed. Pick up is scheduled for ${pickup_date} (${pickup_time_slot}).`;
    await query(
      'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
      [req.user?.id, notificationTitle, notificationMsg]
    );

    await query('COMMIT');

    return res.status(201).json({
      message: 'Order created successfully',
      order: createdOrder,
      items: itemsWithPricing
    });
  } catch (err: any) {
    await query('ROLLBACK');
    console.error('Error creating order:', err);
    return res.status(500).json({ error: 'Failed to complete order booking transaction' });
  }
});

/**
 * GET /orders
 * Retrieves order history for authenticated customer, or all orders if Admin
 */
router.get('/', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  try {
    let ordersQuery = `
      SELECT o.*, a.address_line_1, a.address_line_2, a.city, a.pincode, u.name as user_name, u.phone as user_phone
      FROM orders o
      LEFT JOIN addresses a ON o.pickup_address_id = a.id
      JOIN users u ON o.user_id = u.id
    `;
    const params = [];

    if (req.user?.role !== 'admin') {
      ordersQuery += ' WHERE o.user_id = $1 ';
      params.push(req.user?.id);
    }

    ordersQuery += ' ORDER BY o.created_at DESC';
    const result = await query(ordersQuery, params);
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve order history' });
  }
});

/**
 * GET /orders/:id
 * Retrieves granular order details including selected items lists
 */
router.get('/:id', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const orderId = parseInt(req.params.id);
  try {
    const orderResult = await query(
      `SELECT o.*, a.address_line_1, a.address_line_2, a.city, a.state, a.pincode, a.tag as address_tag, u.name as user_name, u.phone as user_phone
       FROM orders o
       LEFT JOIN addresses a ON o.pickup_address_id = a.id
       JOIN users u ON o.user_id = u.id
       WHERE o.id = $1`,
      [orderId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderResult.rows[0];

    // Check auth boundary: user can only view their own orders unless admin
    if (req.user?.role !== 'admin' && order.user_id !== req.user?.id) {
      return res.status(403).json({ error: 'Access denied to this order detail' });
    }

    // Fetch order items detail
    const itemsResult = await query(
      `SELECT oi.*, i.name as item_name, i.category as item_category, s.name as service_name
       FROM order_items oi
       JOIN items i ON oi.item_id = i.id
       JOIN services s ON oi.service_id = s.id
       WHERE oi.order_id = $1`,
      [orderId]
    );

    return res.status(200).json({
      order,
      items: itemsResult.rows
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to load order detailed view' });
  }
});

/**
 * PUT /orders/:id/status
 * Updates order lifecycle status (Admin only)
 */
router.put('/:id/status', authenticateToken, authorizeRoles('admin'), async (req: AuthenticatedRequest, res: Response) => {
  const orderId = parseInt(req.params.id);
  const { status } = req.body;

  const validStatuses = [
    'created', 'pickup_scheduled', 'pickup_completed', 'processing',
    'washing', 'drying', 'ironing', 'quality_check', 'ready_for_delivery',
    'out_for_delivery', 'delivered'
  ];

  if (!status || !validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid order status code' });
  }

  try {
    const result = await query(
      'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, orderId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const updatedOrder = result.rows[0];

    // Create user notification on update
    const title = `Order Status Updated`;
    const message = `Your laundry order #${orderId} is now: ${status.replace(/_/g, ' ').toUpperCase()}.`;
    await query(
      'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
      [updatedOrder.user_id, title, message]
    );

    return res.status(200).json({
      message: 'Order status successfully updated',
      order: updatedOrder
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to update order status' });
  }
});

/**
 * PUT /orders/:id/payment-status
 * Updates payment status (Admin only or verified hook)
 */
router.put('/:id/payment-status', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  const orderId = parseInt(req.params.id);
  const { payment_status } = req.body;
  const validPaymentStatuses = ['pending', 'paid', 'failed', 'refunded'];

  if (!payment_status || !validPaymentStatuses.includes(payment_status)) {
    return res.status(400).json({ error: 'Invalid payment status key' });
  }

  try {
    const result = await query(
      'UPDATE orders SET payment_status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [payment_status, orderId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }
    return res.status(200).json({ message: 'Payment status updated', order: result.rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'Database update failed' });
  }
});

export default router;
