import { Router, Response } from 'express';
import { query } from '../config/db';
import { AuthenticatedRequest, authenticateToken, authorizeRoles } from '../middleware/auth';

const router = Router();

/**
 * GET /coupons
 * Retrieves active coupons for checkout selection list
 */
router.get('/', async (req, res) => {
  try {
    const result = await query(
      "SELECT * FROM coupons WHERE status = 'active' AND expiry_date > NOW() ORDER BY id DESC"
    );
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch coupons list' });
  }
});

/**
 * POST /coupons/validate
 * Validates a coupon code against minimum order thresholds
 * Request body: { code: string, amount: number }
 */
router.post('/validate', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const { code, amount } = req.body;

  if (!code || amount === undefined) {
    return res.status(400).json({ error: 'Coupon code and order amount are required' });
  }

  try {
    const result = await query(
      "SELECT * FROM coupons WHERE code = $1 AND status = 'active' AND expiry_date > NOW()",
      [code.toUpperCase()]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ valid: false, error: 'Coupon is invalid or has expired' });
    }

    const coupon = result.rows[0];
    const minOrderVal = parseFloat(coupon.min_order_value);
    
    if (amount < minOrderVal) {
      return res.status(400).json({
        valid: false,
        error: `Minimum order amount of ₹${minOrderVal} required to apply this coupon`
      });
    }

    let discountAmount = 0;
    const discountVal = parseFloat(coupon.discount_value);

    if (coupon.discount_type === 'flat') {
      discountAmount = Math.min(discountVal, amount);
    } else if (coupon.discount_type === 'percentage') {
      discountAmount = parseFloat(((amount * discountVal) / 100).toFixed(2));
    }

    return res.status(200).json({
      valid: true,
      code: coupon.code,
      discount_type: coupon.discount_type,
      discount_value: discountVal,
      discount_amount: discountAmount
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to validate coupon code' });
  }
});

/**
 * POST /coupons
 * Creates a new coupon code. Admin restricted.
 */
router.post('/', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  const { code, discount_type, discount_value, min_order_value, expiry_date, status } = req.body;

  if (!code || !discount_type || discount_value === undefined || !expiry_date) {
    return res.status(400).json({ error: 'Missing required coupon definitions' });
  }

  try {
    const result = await query(
      `INSERT INTO coupons (code, discount_type, discount_value, min_order_value, expiry_date, status)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [code.toUpperCase(), discount_type, discount_value, min_order_value || 0.00, expiry_date, status || 'active']
    );
    return res.status(201).json(result.rows[0]);
  } catch (err: any) {
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Coupon code already exists' });
    }
    return res.status(500).json({ error: 'Failed to create coupon' });
  }
});

/**
 * PUT /coupons/:id
 * Updates coupon code settings. Admin restricted.
 */
router.put('/:id', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  const couponId = parseInt(req.params.id);
  const { code, discount_type, discount_value, min_order_value, expiry_date, status } = req.body;

  try {
    const result = await query(
      `UPDATE coupons 
       SET code = $1, discount_type = $2, discount_value = $3, min_order_value = $4, expiry_date = $5, status = $6
       WHERE id = $7 RETURNING *`,
      [code.toUpperCase(), discount_type, discount_value, min_order_value, expiry_date, status, couponId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Coupon not found' });
    }

    return res.status(200).json(result.rows[0]);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to update coupon details' });
  }
});

/**
 * DELETE /coupons/:id
 * Deletes coupon code. Admin restricted.
 */
router.delete('/:id', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  const couponId = parseInt(req.params.id);
  try {
    const result = await query('DELETE FROM coupons WHERE id = $1 RETURNING *', [couponId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Coupon not found' });
    }
    return res.status(200).json({ message: 'Coupon code successfully deleted' });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to delete coupon' });
  }
});

export default router;
