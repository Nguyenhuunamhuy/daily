const { getDb } = require('./src/db');

async function run() {
  try {
    const db = await getDb();
    await db.run("ALTER TABLE entries ADD COLUMN entry_date BIGINT");
    // Also we should set existing entry_date to created_at
    await db.run("UPDATE entries SET entry_date = created_at WHERE entry_date IS NULL");
    await db.run("ALTER TABLE entries MODIFY COLUMN entry_date BIGINT NOT NULL");
    console.log("Database altered successfully.");
  } catch (e) {
    if (e.message && e.message.includes('Duplicate column name')) {
      console.log('Column already exists, ignoring.');
    } else {
      console.error("Error:", e);
    }
  } finally {
    process.exit(0);
  }
}

run();
