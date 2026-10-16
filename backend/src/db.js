const path = require('path');
const dotenv = require('dotenv');
const { Pool } = require('pg');

dotenv.config({ path: path.join(__dirname, '..', '.env') });
dotenv.config({ path: path.join(__dirname, '..', '..', '.env') });

function createPool() {
  if (process.env.DATABASE_URL) {
    const local = /localhost|127\.0\.0\.1/.test(process.env.DATABASE_URL);
    return new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: local ? false : { rejectUnauthorized: false },
      max: 10,
    });
  }

  return new Pool({
    host: process.env.PGHOST || 'localhost',
    port: Number(process.env.PGPORT) || 5432,
    database: process.env.PGDATABASE || 'sert_biblionet',
    user: process.env.PGUSER || 'sert_app',
    password: process.env.PGPASSWORD,
    max: 10,
  });
}

const pool = createPool();

function query(text, params) {
  return pool.query(text, params);
}

module.exports = { pool, query };
