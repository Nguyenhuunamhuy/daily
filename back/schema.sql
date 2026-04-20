-- MySQL schema for Diary backend

CREATE TABLE IF NOT EXISTS entries (
  id VARCHAR(100) PRIMARY KEY,
  title VARCHAR(255),
  content TEXT NOT NULL,
  entry_date BIGINT NOT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  INDEX idx_entries_created_at (created_at DESC)
);

CREATE TABLE IF NOT EXISTS photos (
  id VARCHAR(100) PRIMARY KEY,
  entry_id VARCHAR(100) NOT NULL,
  filename VARCHAR(255) NOT NULL,
  url VARCHAR(1000) NOT NULL,
  created_at BIGINT NOT NULL,
  FOREIGN KEY(entry_id) REFERENCES entries(id) ON DELETE CASCADE,
  INDEX idx_photos_entry_id (entry_id)
);
