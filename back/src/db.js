const path = require("path");
const fs = require("fs/promises");

const { open } = require("sqlite");
const sqlite3 = require("sqlite3");

const DB_DIR = path.join(__dirname, "..", "data");
const DB_PATH = path.join(DB_DIR, "diary.sqlite");
const SCHEMA_PATH = path.join(__dirname, "..", "schema.sql");

let _dbPromise = null;

async function ensureDir(dirPath) {
  await fs.mkdir(dirPath, { recursive: true });
}

async function getDb() {
  if (_dbPromise) return _dbPromise;

  _dbPromise = (async () => {
    await ensureDir(DB_DIR);
    const db = await open({
      filename: DB_PATH,
      driver: sqlite3.Database,
    });

    await db.exec("PRAGMA foreign_keys = ON;");

    const schema = await fs.readFile(SCHEMA_PATH, "utf8");
    await db.exec(schema);

    return db;
  })();

  return _dbPromise;
}

module.exports = { getDb, DB_PATH };

