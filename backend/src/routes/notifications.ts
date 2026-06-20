import { Router, Response } from 'express';
import { query } from '../config/db';
import { AuthenticatedRequest, authenticateToken } from '../middleware/auth';

const router = Router();

/**
 * GET /notifications
 * Retrieves notifications for the active user
 */
router.get('/', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const result = await query(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [req.user?.id]
    );
    return res.status(200).json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to retrieve notifications' });
  }
});

/**
 * PUT /notifications/:id/read
 * Marks a notification as read
 */
router.put('/:id/read', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  const notificationId = parseInt(req.params.id);
  try {
    const result = await query(
      "UPDATE notifications SET status = 'read' WHERE id = $1 AND user_id = $2 RETURNING *",
      [notificationId, req.user?.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notification alert not found' });
    }
    return res.status(200).json(result.rows[0]);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to update notification state' });
  }
});

/**
 * PUT /notifications/read-all
 * Marks all notifications as read for current user
 */
router.put('/read-all', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  try {
    await query(
      "UPDATE notifications SET status = 'read' WHERE user_id = $1 AND status = 'unread'",
      [req.user?.id]
    );
    return res.status(200).json({ message: 'All notifications marked as read' });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to update notification state' });
  }
});

export default router;
