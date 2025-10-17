import pkg from "pg";
import dotenv from "dotenv";
dotenv.config();

const { Pool } = pkg;
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Table creation (run once)
export async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS orders (
      id SERIAL PRIMARY KEY,
      order_id VARCHAR(50) UNIQUE,
      amount NUMERIC(10,2),
      status VARCHAR(20),
      qr_payload TEXT,
      created_at TIMESTAMP DEFAULT NOW()
    );
  `);
}
