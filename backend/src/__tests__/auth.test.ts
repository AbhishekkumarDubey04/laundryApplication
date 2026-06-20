import request from 'supertest';
import app from '../app';
import { query } from '../config/db';

// Enable auto-mocking for the database config module
jest.mock('../config/db');

describe('Authentication API Endpoint Tests', () => {
  beforeEach(() => {
    // Clear all mock history before each test run
    jest.clearAllMocks();
  });

  it('should successfully send mock OTP', async () => {
    const response = await request(app)
      .post('/api/auth/send-otp')
      .send({ phone: '+919999999999' });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('message');
    expect(response.body.phone).toBe('+919999999999');
    expect(response.body).toHaveProperty('debugOtp');
  });

  it('should reject invalid or missing OTP on verify', async () => {
    const response = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: '+919999999999', otp: 'wrong_otp' });

    expect(response.status).toBe(400);
    expect(response.body).toHaveProperty('error');
  });

  it('should authenticate user with default sandbox OTP 123456', async () => {
    // Mock the query behavior to return the admin user when selecting by phone
    (query as jest.Mock).mockResolvedValue({
      rows: [{ id: 1, name: 'Admin India', phone: '+919999999999', role: 'admin', email: 'admin@laundryapp.in' }]
    });

    const response = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: '+919999999999', otp: '123456' });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
    expect(response.body).toHaveProperty('user');
    expect(response.body.user.role).toBe('admin');
  });
});
