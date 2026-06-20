import { Router, Response } from 'express';
import { query } from '../config/db';
import * as jwt from 'jsonwebtoken';
import { AuthenticatedRequest, authenticateToken } from '../middleware/auth';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_key_laundry_india_2026';

// Temporary memory store for OTP codes during runtime
const otpStore = new Map<string, string>();

/**
 * POST /auth/send-otp
 * Request body: { phone: string }
 */
router.post('/send-otp', async (req, res) => {
  const { phone } = req.body;

  if (!phone || typeof phone !== 'string') {
    return res.status(400).json({ error: 'Valid phone number is required' });
  }

  // standard mock OTP for testing
  const mockOtp = phone === '+919999999999' ? '123456' : Math.floor(100000 + Math.random() * 900000).toString();
  
  otpStore.set(phone, mockOtp);
  console.log(`[OTP SERVICE] Sent OTP code [${mockOtp}] to phone [${phone}]`);

  return res.status(200).json({
    message: 'OTP sent successfully (Simulated)',
    phone,
    // Return OTP directly in response for local testing ease
    debugOtp: mockOtp
  });
});

/**
 * POST /auth/verify-otp
 * Request body: { phone: string, otp: string }
 */
router.post('/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;

  if (!phone || !otp) {
    return res.status(400).json({ error: 'Phone number and OTP code are required' });
  }

  const storedOtp = otpStore.get(phone);

  // Accept static '123456' as fallback mock for test convenience
  if (otp !== storedOtp && otp !== '123456') {
    return res.status(400).json({ error: 'Invalid or expired OTP code' });
  }

  // Clear OTP from memory store once verified
  otpStore.delete(phone);

  try {
    // Check if user exists
    let userResult = await query('SELECT * FROM users WHERE phone = $1', [phone]);
    let user = userResult.rows[0];

    if (!user) {
      // Create a default customer account
      const defaultName = phone === '+919999999999' ? 'Admin India' : `Customer ${phone.slice(-4)}`;
      const defaultRole = phone === '+919999999999' ? 'admin' : 'customer';

      const insertResult = await query(
        'INSERT INTO users (name, phone, role) VALUES ($1, $2, $3) RETURNING *',
        [defaultName, phone, defaultRole]
      );
      user = insertResult.rows[0];
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        id: user.id,
        phone: user.phone,
        role: user.role,
        name: user.name
      },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      message: 'Authentication successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role
      }
    });
  } catch (err: any) {
    console.error('Error during OTP verification query:', err);
    return res.status(500).json({ error: 'Database verification failed' });
  }
});

/**
 * GET /auth/me
 * Retrieves active user details from the JWT
 */
router.get('/me', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userResult = await query('SELECT id, name, phone, email, role FROM users WHERE id = $1', [req.user?.id]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User profile not found' });
    }
    return res.status(200).json({ user: userResult.rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve profile data' });
  }
});

/**
 * PUT /auth/profile
 * Updates active user name & email
 */
router.put('/profile', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const { name, email } = req.body;
  try {
    const updateResult = await query(
      'UPDATE users SET name = $1, email = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING id, name, phone, email, role',
      [name, email, req.user?.id]
    );
    return res.status(200).json({ user: updateResult.rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to update profile' });
  }
});

export default router;
