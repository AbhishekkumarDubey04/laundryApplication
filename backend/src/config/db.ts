import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'laundary_db',
  password: process.env.DB_PASSWORD || 'laundrypass',
  port: parseInt(process.env.DB_PORT || '5432'),
});

pool.on('connect', () => {
  console.log('Connected to the PostgreSQL database.');
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle database client', err);
});

export const query = (text: string, params?: any[]) => pool.query(text, params);

export const initDatabase = async () => {
  let retries = 5;
  while (retries > 0) {
    try {
      console.log('Testing database connection...');
      const client = await pool.connect();
      console.log('Successfully connected to database. Setting up schema...');
      
      const sqlPath = path.join(__dirname, 'init.sql');
      if (fs.existsSync(sqlPath)) {
        const sql = fs.readFileSync(sqlPath, 'utf8');
        await client.query(sql);
        console.log('Database tables successfully initialized.');
      } else {
        console.warn('init.sql not found! Table schemas might be missing.');
      }
      
      client.release();
      break;
    } catch (err: any) {
      retries -= 1;
      console.error(`Database connection failed. Retries remaining: ${retries}. Error:`, err.message);
      if (retries === 0) {
        throw new Error('Could not connect to the database after multiple attempts.');
      }
      // Wait 3 seconds before retrying
      await new Promise((resolve) => setTimeout(resolve, 3000));
    }
  }
};

export default pool;
