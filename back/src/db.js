const path = require("path");
const fs = require("fs/promises");
require("dotenv").config();
const mysql = require("mysql2/promise");

const DB_HOST = process.env.DB_HOST || "localhost";
const DB_USER = process.env.DB_USER || "root";
const DB_PASSWORD = process.env.DB_PASSWORD || "";
const DB_NAME = process.env.DB_NAME || "diary";

let _dbPromise = null;

async function getDb() {
  if (_dbPromise) return _dbPromise;

  _dbPromise = (async () => {
    // 1. Create DB if it doesn't exist
    const connection = await mysql.createConnection({
      host: DB_HOST,
      user: DB_USER,
      password: DB_PASSWORD,
    });
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\``);
    await connection.end();

    // 2. Connect to the specified DB
    const pool = mysql.createPool({
      host: DB_HOST,
      user: DB_USER,
      password: DB_PASSWORD,
      database: DB_NAME,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      multipleStatements: true, // required to run the full schema script at once
    });

    // 3. Run schema setup
    const schemaPath = path.join(__dirname, "..", "schema.sql");
    const schema = await fs.readFile(schemaPath, "utf8");
    try {
      await pool.query(schema);
    } catch (e) {
      console.error("Error creating tables:", e);
    }

    // 4. Return wrapper API to maintain compatibility with existing SQLite calls (get, all, run)
    return {
      async get(sql, params = []) {
        const [rows] = await pool.execute(sql, params);
        return rows[0];
      },
      async all(sql, params = []) {
        const [rows] = await pool.execute(sql, params);
        return rows;
      },
      async run(sql, params = []) {
        const [result] = await pool.execute(sql, params);
        return result;
      }
    };
  })();

  return _dbPromise;
}

module.exports = { getDb };
