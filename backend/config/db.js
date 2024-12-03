const sql = require('mssql');
const dotenv = require('dotenv');

dotenv.config({ path: './config/.env' });

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_HOST,
  database: process.env.DB_NAME,
  options: {
    encrypt: true,  // Use encryption
    trustServerCertificate: true,  // Required for local dev without SSL cert
  },
};

let poolPromise;

const connectToDatabase = async () => {
  if (!poolPromise) {
    poolPromise = sql.connect(config) 
      .then(pool => pool)
      .catch(err => console.error('Database connection failed: ', err));
  }
  return poolPromise;
};

module.exports = { sql, connectToDatabase };
 