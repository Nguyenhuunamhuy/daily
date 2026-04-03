-- SQLite schema for Diary backend (Week 3 design)
-- Lưu ý: Tuần 4 sẽ dùng file này để tạo DB thật.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS entries (
  id TEXT PRIMARY KEY,
  title TEXT,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_entries_created_at ON entries(created_at DESC);

CREATE TABLE IF NOT EXISTS photos (
  id TEXT PRIMARY KEY,
  entry_id TEXT NOT NULL,
  filename TEXT NOT NULL,
  url TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY(entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_photos_entry_id ON photos(entry_id);

