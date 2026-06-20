import { Router, Response } from 'express';
import { query } from '../config/db';
import { AuthenticatedRequest, authenticateToken } from '../middleware/auth';
import * as crypto from 'crypto';
import Razorpay from 'razorpay';

const router = Router();

const KEY_ID = process.env.RAZORPAY_KEY_ID || 'rzp_test_mockKeyId12345';
const KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || 'mockSecretKeyLaundryApp2026';

// Instantiate Razorpay only if keys are not mock values
let razorpayInstance: Razorpay | null = null;
const isMockMode = KEY_ID.includes('mock') || KEY_SECRET.includes('mock');

if (!isMockMode) {
  try {
    razorpayInstance = new Razorpay({
      key_id: KEY_ID,
      key_secret: KEY_SECRET
    });
    console.log('Razorpay SDK initialized successfully.');
  } catch (error) {
    console.error('Failed to initialize Razorpay SDK. Operating in mock mode.', error);
  }
} else {
  console.log('Razorpay operates in Mock Sandbox mode.');
}

/**
 * POST /payments/create
 * Creates a Razorpay transaction order.
 * Request body: { order_id: number, method: 'razorpay' | 'cod' }
 */
router.post('/create', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const { order_id, method } = req.body;

  if (!order_id || !method) {
    return res.status(400).json({ error: 'Order ID and payment method are required' });
  }

  try {
    // 1. Fetch order details
    const orderResult = await query('SELECT * FROM orders WHERE id = $1', [order_id]);
    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order details not found' });
    }

    const order = orderResult.rows[0];

    // Auth validation
    if (order.user_id !== req.user?.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (method === 'cod') {
      // Cash on Delivery flow
      await query('BEGIN');
      await query(
        `UPDATE orders 
         SET payment_status = 'pending', status = 'pickup_scheduled', updated_at = CURRENT_TIMESTAMP 
         WHERE id = $1`,
        [order_id]
      );
      await query(
        `INSERT INTO payments (order_id, payment_gateway, amount, status) 
         VALUES ($1, 'cod', $2, 'pending')`,
        [order_id, order.grand_total]
      );
      await query('COMMIT');
      return res.status(200).json({ message: 'COD selected. Order scheduled.', gateway: 'cod' });
    }

    // Razorpay flow
    const amountInPaise = Math.round(parseFloat(order.grand_total) * 100);

    if (isMockMode || !razorpayInstance) {
      const mockRazorpayOrderId = `order_mock_${Math.random().toString(36).substr(2, 9)}`;
      return res.status(200).json({
        gateway: 'razorpay',
        mock: true,
        key_id: KEY_ID,
        amount: amountInPaise,
        currency: 'INR',
        id: mockRazorpayOrderId,
        notes: { order_id: order.id }
      });
    }

    // Create real Razorpay order
    const options = {
      amount: amountInPaise,
      currency: 'INR',
      receipt: `receipt_order_${order.id}`,
      notes: { order_id: order.id.toString() }
    };

    const razorpayOrder = await razorpayInstance.orders.create(options);
    return res.status(200).json({
      gateway: 'razorpay',
      mock: false,
      key_id: KEY_ID,
      ...razorpayOrder
    });
  } catch (err: any) {
    console.error('Error creating payment order:', err);
    return res.status(500).json({ error: 'Payment initialization failed' });
  }
});

/**
 * POST /payments/verify
 * Verifies Razorpay signature and updates transaction status
 * Request body: { order_id: number, razorpay_payment_id: string, razorpay_order_id: string, razorpay_signature: string }
 */
router.post('/verify', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const { order_id, razorpay_payment_id, razorpay_order_id, razorpay_signature } = req.body;

  if (!order_id || !razorpay_payment_id || !razorpay_order_id) {
    return res.status(400).json({ error: 'Missing payment signature verification parameters' });
  }

  try {
    // Check order existence
    const orderResult = await query('SELECT * FROM orders WHERE id = $1', [order_id]);
    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }
    const order = orderResult.rows[0];

    let signatureVerified = false;

    if (isMockMode) {
      // Mock verification: accept mock signature format
      signatureVerified = true;
    } else if (razorpay_signature) {
      // Real signature verification: HMAC-SHA256 signature verification
      const body = razorpay_order_id + '|' + razorpay_payment_id;
      const expectedSignature = crypto
        .createHmac('sha256', KEY_SECRET)
        .update(body.toString())
        .digest('hex');

      signatureVerified = expectedSignature === razorpay_signature;
    }

    if (!signatureVerified) {
      return res.status(400).json({ error: 'Payment signature validation failed' });
    }

    // Update order status to paid & set flow to pickup_scheduled
    await query('BEGIN');

    await query(
      `UPDATE orders 
       SET payment_status = 'paid', status = 'pickup_scheduled', updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1`,
      [order_id]
    );

    // Insert payment transaction log
    await query(
      `INSERT INTO payments (order_id, payment_gateway, transaction_id, payment_id, signature, amount, status)
       VALUES ($1, 'razorpay', $2, $3, $4, $5, 'captured')`,
      [order_id, razorpay_order_id, razorpay_payment_id, razorpay_signature || 'mock_sig', order.grand_total, 'captured']
    );

    // Create payment notification
    await query(
      'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
      [
        order.user_id,
        'Payment Successful!',
        `Thank you! Payment of ₹${order.grand_total} for order #${order_id} was successfully verified.`
      ]
    );

    await query('COMMIT');

    return res.status(200).json({ message: 'Payment successfully verified', order_id });
  } catch (err: any) {
    await query('ROLLBACK');
    console.error('Error verifying payment:', err);
    return res.status(500).json({ error: 'Failed to verify payment signature' });
  }
});

export default router;
