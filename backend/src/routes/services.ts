import { Router, Response } from 'express';
import { query } from '../config/db';
import { AuthenticatedRequest, authenticateToken, authorizeRoles } from '../middleware/auth';

const router = Router();

/**
 * GET /services
 * Retrieves active services grouped with their related items and pricing
 */
router.get('/', async (req, res) => {
  try {
    const pricingQuery = `
      SELECT 
        s.id as service_id, s.name as service_name, s.description as service_desc, s.image as service_img, s.status as service_status,
        i.id as item_id, i.name as item_name, i.category as item_category, i.image as item_img,
        sp.id as pricing_id, sp.price
      FROM services s
      INNER JOIN service_pricing sp ON s.id = sp.service_id
      INNER JOIN items i ON sp.item_id = i.id
      WHERE s.status = 'active'
      ORDER BY s.id, i.category, i.name;
    `;
    const result = await query(pricingQuery);
    
    // Group items by services
    const servicesMap = new Map();
    
    for (const row of result.rows) {
      if (!servicesMap.has(row.service_id)) {
        servicesMap.set(row.service_id, {
          id: row.service_id,
          name: row.service_name,
          description: row.service_desc,
          image: row.service_img,
          status: row.service_status,
          items: []
        });
      }
      
      servicesMap.get(row.service_id).items.push({
        id: row.item_id,
        name: row.item_name,
        category: row.item_category,
        image: row.item_img,
        pricing_id: row.pricing_id,
        price: parseFloat(row.price)
      });
    }

    return res.status(200).json(Array.from(servicesMap.values()));
  } catch (err: any) {
    console.error('Error fetching service rates:', err);
    return res.status(500).json({ error: 'Failed to retrieve laundry rates' });
  }
});

/**
 * GET /services/items
 * Retrieves a plain list of all standard items (clothes types) in catalog
 */
router.get('/items', async (req, res) => {
  try {
    const result = await query('SELECT * FROM items ORDER BY category, name');
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve item catalog' });
  }
});

/**
 * GET /services/raw-pricing
 * Retrieves flat pricing rows for easy admin management editing tables
 */
router.get('/raw-pricing', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const pricingQuery = `
      SELECT 
        sp.id, sp.price,
        s.id as service_id, s.name as service_name,
        i.id as item_id, i.name as item_name, i.category as item_category
      FROM service_pricing sp
      JOIN services s ON sp.service_id = s.id
      JOIN items i ON sp.item_id = i.id
      ORDER BY s.name, i.category, i.name;
    `;
    const result = await query(pricingQuery);
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to load raw pricing list' });
  }
});

/**
 * POST /services/pricing
 * Adds or Updates service item pricing. Admin restricted.
 * Request body: { service_id: number, item_id: number, price: number }
 */
router.post('/pricing', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  const { service_id, item_id, price } = req.body;
  if (!service_id || !item_id || price === undefined || price < 0) {
    return res.status(400).json({ error: 'Invalid parameters. Price must be positive.' });
  }
  try {
    const result = await query(
      `INSERT INTO service_pricing (service_id, item_id, price)
       VALUES ($1, $2, $3)
       ON CONFLICT (service_id, item_id) 
       DO UPDATE SET price = EXCLUDED.price
       RETURNING *`,
      [service_id, item_id, price]
    );
    return res.status(200).json({ message: 'Pricing configured successfully', pricing: result.rows[0] });
  } catch (err: any) {
    return res.status(500).json({ error: 'Database pricing update failed' });
  }
});

/**
 * DELETE /services/pricing/:id
 * Deletes pricing configuration. Admin restricted.
 */
router.delete('/pricing/:id', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  const pricingId = parseInt(req.params.id);
  try {
    await query('DELETE FROM service_pricing WHERE id = $1', [pricingId]);
    return res.status(200).json({ message: 'Pricing row deleted successfully' });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to delete pricing row' });
  }
});

export default router;
