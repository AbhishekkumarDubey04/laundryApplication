import { Router, Response } from 'express';
import { query } from '../config/db';
import { AuthenticatedRequest, authenticateToken } from '../middleware/auth';

const router = Router();

/**
 * GET /addresses
 * Retrieves list of addresses registered to the customer
 */
router.get('/', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const result = await query(
      'SELECT * FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, id DESC',
      [req.user?.id]
    );
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve addresses' });
  }
});

/**
 * POST /addresses
 * Registers a new address for the customer
 */
router.post('/', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const { address_line_1, address_line_2, city, state, pincode, latitude, longitude, is_default, tag } = req.body;

  if (!address_line_1 || !city || !state || !pincode) {
    return res.status(400).json({ error: 'Address line 1, city, state, and pincode are required' });
  }

  try {
    await query('BEGIN');

    // If marked as default, clear pre-existing default address for this user
    if (is_default) {
      await query('UPDATE addresses SET is_default = false WHERE user_id = $1', [req.user?.id]);
    }

    const insertQuery = `
      INSERT INTO addresses (
        user_id, address_line_1, address_line_2, city, state, pincode, 
        latitude, longitude, is_default, tag
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *;
    `;
    const params = [
      req.user?.id,
      address_line_1,
      address_line_2 || null,
      city,
      state,
      pincode,
      latitude ? parseFloat(latitude) : null,
      longitude ? parseFloat(longitude) : null,
      is_default || false,
      tag || 'Home'
    ];

    const result = await query(insertQuery, params);
    const newAddress = result.rows[0];

    // If this is the only address, force it to be default
    const countResult = await query('SELECT count(*) FROM addresses WHERE user_id = $1', [req.user?.id]);
    if (parseInt(countResult.rows[0].count) === 1 && !newAddress.is_default) {
      const updateDefault = await query(
        'UPDATE addresses SET is_default = true WHERE id = $1 RETURNING *',
        [newAddress.id]
      );
      newAddress.is_default = true;
    }

    await query('COMMIT');
    return res.status(201).json(newAddress);
  } catch (err: any) {
    await query('ROLLBACK');
    console.error('Error creating address:', err);
    return res.status(500).json({ error: 'Failed to save address' });
  }
});

/**
 * PUT /addresses/:id
 * Updates address details
 */
router.put('/:id', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const addressId = parseInt(req.params.id);
  const { address_line_1, address_line_2, city, state, pincode, latitude, longitude, is_default, tag } = req.body;

  try {
    // Check ownership
    const checkOwnership = await query('SELECT user_id FROM addresses WHERE id = $1', [addressId]);
    if (checkOwnership.rows.length === 0) {
      return res.status(404).json({ error: 'Address not found' });
    }
    if (checkOwnership.rows[0].user_id !== req.user?.id) {
      return res.status(403).json({ error: 'Unauthorized operation' });
    }

    await query('BEGIN');

    if (is_default) {
      await query('UPDATE addresses SET is_default = false WHERE user_id = $1', [req.user?.id]);
    }

    const updateQuery = `
      UPDATE addresses 
      SET address_line_1 = $1, address_line_2 = $2, city = $3, state = $4, pincode = $5,
          latitude = $6, longitude = $7, is_default = $8, tag = $9
      WHERE id = $10 RETURNING *;
    `;
    const params = [
      address_line_1,
      address_line_2 || null,
      city,
      state,
      pincode,
      latitude ? parseFloat(latitude) : null,
      longitude ? parseFloat(longitude) : null,
      is_default || false,
      tag || 'Home',
      addressId
    ];

    const result = await query(updateQuery, params);
    await query('COMMIT');
    return res.status(200).json(result.rows[0]);
  } catch (err) {
    await query('ROLLBACK');
    return res.status(500).json({ error: 'Failed to update address' });
  }
});

/**
 * DELETE /addresses/:id
 * Deletes address
 */
router.delete('/:id', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const addressId = parseInt(req.params.id);
  try {
    // Check ownership
    const checkResult = await query('SELECT user_id, is_default FROM addresses WHERE id = $1', [addressId]);
    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Address not found' });
    }
    if (checkResult.rows[0].user_id !== req.user?.id) {
      return res.status(403).json({ error: 'Unauthorized operation' });
    }

    await query('BEGIN');
    await query('DELETE FROM addresses WHERE id = $1', [addressId]);

    // If deleted address was default, promote the next address to default
    if (checkResult.rows[0].is_default) {
      const nextAddress = await query(
        'SELECT id FROM addresses WHERE user_id = $1 ORDER BY id DESC LIMIT 1',
        [req.user?.id]
      );
      if (nextAddress.rows.length > 0) {
        await query('UPDATE addresses SET is_default = true WHERE id = $1', [nextAddress.rows[0].id]);
      }
    }

    await query('COMMIT');
    return res.status(200).json({ message: 'Address successfully deleted' });
  } catch (err) {
    await query('ROLLBACK');
    return res.status(500).json({ error: 'Failed to delete address' });
  }
});

export default router;
