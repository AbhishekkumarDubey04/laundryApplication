import express from 'express';
import cors from 'cors';
import * as dotenv from 'dotenv';
import authRouter from './routes/auth';
import servicesRouter from './routes/services';
import ordersRouter from './routes/orders';
import paymentsRouter from './routes/payments';
import couponsRouter from './routes/coupons';
import addressesRouter from './routes/addresses';
import notificationsRouter from './routes/notifications';
import adminRouter from './routes/admin';

// Swagger integration
import swaggerUi from 'swagger-ui-express';
import * as fs from 'fs';
import * as path from 'path';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// Routes mounts
app.use('/api/auth', authRouter);
app.use('/api/services', servicesRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api/coupons', couponsRouter);
app.use('/api/addresses', addressesRouter);
app.use('/api/notifications', notificationsRouter);
app.use('/api/admin', adminRouter);

// Swagger Documentation mounting
const swaggerPath = path.join(__dirname, 'swagger', 'swagger.json');
if (fs.existsSync(swaggerPath)) {
  try {
    const swaggerDocument = JSON.parse(fs.readFileSync(swaggerPath, 'utf8'));
    app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
    console.log('Swagger API documentation loaded at: http://localhost:5000/api/docs');
  } catch (error) {
    console.error('Failed to parse swagger.json file:', error);
  }
} else {
  console.warn(`Swagger definition file not found at ${swaggerPath}. Skipping docs mount.`);
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
});

// Generic 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Express Error Handler caught exception:', err);
  res.status(500).json({ error: 'Internal server error occurred' });
});

export default app;
