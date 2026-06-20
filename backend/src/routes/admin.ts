import { Router, Response } from 'express';
import { query } from '../config/db';
import { AuthenticatedRequest, authenticateToken, authorizeRoles } from '../middleware/auth';

const router = Router();

/**
 * GET /admin/dashboard-stats
 * Retrieves key aggregates for the metrics display cards
 */
router.get('/dashboard-stats', authenticateToken, authorizeRoles('admin'), async (req: AuthenticatedRequest, res: Response) => {
  try {
    // 1. Today's orders count
    const todayOrdersResult = await query(
      `SELECT count(*) FROM orders 
       WHERE created_at >= CURRENT_DATE`
    );
    const todayOrders = parseInt(todayOrdersResult.rows[0].count);

    // 2. Today's revenue
    const todayRevenueResult = await query(
      `SELECT sum(grand_total) FROM orders 
       WHERE created_at >= CURRENT_DATE AND payment_status = 'paid'`
    );
    const todayRevenue = parseFloat(todayRevenueResult.rows[0].sum || '0.00');

    // 3. Pending orders (active, not yet delivered)
    const pendingOrdersResult = await query(
      `SELECT count(*) FROM orders 
       WHERE status NOT IN ('delivered')`
    );
    const pendingOrders = parseInt(pendingOrdersResult.rows[0].count);

    // 4. Total registered customers
    const totalCustomersResult = await query(
      `SELECT count(*) FROM users 
       WHERE role = 'customer'`
    );
    const totalCustomers = parseInt(totalCustomersResult.rows[0].count);

    // 5. Total delivered orders count
    const deliveredOrdersResult = await query(
      `SELECT count(*) FROM orders 
       WHERE status = 'delivered'`
    );
    const deliveredOrders = parseInt(deliveredOrdersResult.rows[0].count);

    // 6. Average order value (AOV)
    const aovResult = await query(
      `SELECT avg(grand_total) FROM orders`
    );
    const averageOrderValue = parseFloat(aovResult.rows[0].avg || '0.00');

    return res.status(200).json({
      todayOrders,
      todayRevenue,
      pendingOrders,
      totalCustomers,
      deliveredOrders,
      averageOrderValue
    });
  } catch (err: any) {
    console.error('Error generating dashboard stats:', err);
    return res.status(500).json({ error: 'Failed to aggregate analytics' });
  }
});

/**
 * GET /admin/revenue-chart
 * Aggregates revenue trends for the last 7 days
 */
router.get('/revenue-chart', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const chartQuery = `
      SELECT 
        to_char(date_series, 'DD Mon') as date_label,
        coalesce(sum(o.grand_total), 0) as revenue,
        count(o.id) as orders_count
      FROM generate_series(
        CURRENT_DATE - INTERVAL '6 days', 
        CURRENT_DATE, 
        '1 day'::interval
      ) date_series
      LEFT JOIN orders o ON o.created_at::date = date_series::date AND o.payment_status = 'paid'
      GROUP BY date_series
      ORDER BY date_series;
    `;
    
    const result = await query(chartQuery);
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to generate revenue chart logs' });
  }
});

/**
 * GET /admin/top-services
 * Returns order breakdown per service category (washing, dry cleaning, steam pressing)
 */
router.get('/top-services', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const serviceDistributionQuery = `
      SELECT s.name as service_name, count(oi.id) as total_items_processed, sum(oi.total_price) as service_revenue
      FROM order_items oi
      JOIN services s ON oi.service_id = s.id
      GROUP BY s.name
      ORDER BY total_items_processed DESC;
    `;
    const result = await query(serviceDistributionQuery);
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve service metrics' });
  }
});

/**
 * GET /admin/customers
 * Retrieves customer profiles and their total spend summary
 */
router.get('/customers', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const customerListQuery = `
      SELECT u.id, u.name, u.phone, u.email, u.created_at,
             count(o.id) as total_orders,
             coalesce(sum(o.grand_total), 0) as total_spend
      FROM users u
      LEFT JOIN orders o ON u.id = o.user_id
      WHERE u.role = 'customer'
      GROUP BY u.id
      ORDER BY total_spend DESC, u.id DESC;
    `;
    const result = await query(customerListQuery);
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to load customer list' });
  }
});

export default router;
