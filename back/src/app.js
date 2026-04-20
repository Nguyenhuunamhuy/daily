const path = require("path");
const fs = require("fs/promises");

const express = require("express");
const cors = require("cors");
const multer = require("multer");

const { getDb } = require("./db");
const { makeId, nowMs, safeExtForUpload, toPublicUploadUrl } = require("./utils");

const UPLOAD_DIR = path.join(__dirname, "..", "uploads");

async function ensureUploadDir() {
  await fs.mkdir(UPLOAD_DIR, { recursive: true });
}

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: "1mb" }));

  app.use("/uploads", express.static(UPLOAD_DIR));

  app.get("/health", (req, res) => {
    res.json({ data: { status: "ok" } });
  });

  // Multer config for photos
  const storage = multer.diskStorage({
    destination: async (req, file, cb) => {
      try {
        await ensureUploadDir();
        cb(null, UPLOAD_DIR);
      } catch (e) {
        cb(e);
      }
    },
    filename: (req, file, cb) => {
      const ext = safeExtForUpload(file.mimetype, file.originalname);
      if (!ext) return cb(new Error("UNSUPPORTED_MEDIA_TYPE"));
      cb(null, `${makeId()}${ext}`);
    },
  });

  const upload = multer({
    storage,
    limits: {
      files: 10,
      fileSize: 5 * 1024 * 1024, // 5MB
    },
    fileFilter: (req, file, cb) => {
      const ext = safeExtForUpload(file.mimetype, file.originalname);
      if (!ext) return cb(new Error("UNSUPPORTED_MEDIA_TYPE"));
      cb(null, true);
    },
  });

  function sendError(res, status, code, message) {
    res.status(status).json({ error: { code, message } });
  }

  // List entries (with optional search + pagination)
  app.get("/api/entries", async (req, res) => {
    try {
      const db = await getDb();
      const page = Math.max(1, Number(req.query.page ?? 1) || 1);
      const limitRaw = Number(req.query.limit ?? 20) || 20;
      const limit = Math.min(100, Math.max(1, limitRaw));
      const offset = (page - 1) * limit;
      const query = (req.query.query ?? "").toString().trim();

      const where = query
        ? "WHERE (title LIKE ? OR content LIKE ?)"
        : "";
      const params = query ? [`%${query}%`, `%${query}%`] : [];

      const totalRow = await db.get(
        `SELECT COUNT(*) as total FROM entries ${where}`,
        params,
      );
      const total = totalRow?.total ?? 0;

      const rows = await db.all(
        `
        SELECT id, title, content, entry_date, created_at, updated_at
        FROM entries
        ${where}
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
        `,
        [...params, limit, offset],
      );

      const ids = rows.map((r) => r.id);
      const photoStatsByEntryId = new Map();
      if (ids.length > 0) {
        const placeholders = ids.map(() => "?").join(",");
        const statsRows = await db.all(
          `
          SELECT
            entry_id,
            COUNT(*) as photoCount,
            MIN(created_at) as firstPhotoCreatedAt
          FROM photos
          WHERE entry_id IN (${placeholders})
          GROUP BY entry_id
          `,
          ids,
        );

        for (const s of statsRows) {
          photoStatsByEntryId.set(s.entry_id, {
            photoCount: s.photoCount,
            firstPhotoCreatedAt: s.firstPhotoCreatedAt,
          });
        }

        // cover photo = earliest uploaded photo (deterministic)
        const coverRows = await db.all(
          `
          SELECT p.entry_id, p.url
          FROM photos p
          JOIN (
            SELECT entry_id, MIN(created_at) as min_created_at
            FROM photos
            WHERE entry_id IN (${placeholders})
            GROUP BY entry_id
          ) x ON x.entry_id = p.entry_id AND x.min_created_at = p.created_at
          `,
          ids,
        );
        const coverByEntryId = new Map(coverRows.map((r) => [r.entry_id, r.url]));

        for (const entryId of ids) {
          const st = photoStatsByEntryId.get(entryId) ?? {
            photoCount: 0,
            firstPhotoCreatedAt: null,
          };
          photoStatsByEntryId.set(entryId, {
            ...st,
            coverPhotoUrl: coverByEntryId.get(entryId) ?? null,
          });
        }
      }

      const items = rows.map((r) => {
        const preview = (r.content ?? "").toString().trim().replace(/\s+/g, " ");
        const contentPreview = preview.length > 120 ? `${preview.slice(0, 120)}...` : preview;
        const stats = photoStatsByEntryId.get(r.id) ?? {
          photoCount: 0,
          coverPhotoUrl: null,
        };

        return {
          id: r.id,
          title: r.title ?? "",
          contentPreview,
          entryDate: r.entry_date ?? r.created_at,
          createdAt: r.created_at,
          updatedAt: r.updated_at,
          coverPhotoUrl: stats.coverPhotoUrl,
          photoCount: stats.photoCount ?? 0,
        };
      });

      res.json({
        data: {
          items,
          page,
          limit,
          total,
        },
      });
    } catch (e) {
      sendError(res, 500, "INTERNAL_ERROR", "Lỗi server");
    }
  });

  // Get entry detail
  app.get("/api/entries/:id", async (req, res) => {
    try {
      const db = await getDb();
      const id = req.params.id;
      const entry = await db.get(
        "SELECT id, title, content, entry_date, created_at, updated_at FROM entries WHERE id = ?",
        [id],
      );
      if (!entry) return sendError(res, 404, "NOT_FOUND", "Không tìm thấy bài nhật ký");

      const photos = await db.all(
        "SELECT id, url, created_at FROM photos WHERE entry_id = ? ORDER BY created_at ASC",
        [id],
      );

      res.json({
        data: {
          id: entry.id,
          title: entry.title ?? "",
          content: entry.content,
          entryDate: entry.entry_date ?? entry.created_at,
          createdAt: entry.created_at,
          updatedAt: entry.updated_at,
          photos: photos.map((p) => ({
            id: p.id,
            url: p.url,
            createdAt: p.created_at,
          })),
        },
      });
    } catch (e) {
      sendError(res, 500, "INTERNAL_ERROR", "Lỗi server");
    }
  });

  // Create entry
  app.post("/api/entries", async (req, res) => {
    try {
      const db = await getDb();
      const title = (req.body?.title ?? "").toString();
      const content = (req.body?.content ?? "").toString().trim();
      if (!content) return sendError(res, 400, "VALIDATION_ERROR", "Nội dung không được rỗng");

      const id = makeId();
      const t = nowMs();
      const entryDate = req.body?.entryDate ?? t;
      await db.run(
        "INSERT INTO entries (id, title, content, entry_date, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
        [id, title, content, entryDate, t, t],
      );

      res.status(201).json({
        data: {
          id,
          title,
          content,
          entryDate,
          createdAt: t,
          updatedAt: t,
          photos: [],
        },
      });
    } catch (e) {
      sendError(res, 500, "INTERNAL_ERROR", "Lỗi server");
    }
  });

  // Update entry
  app.put("/api/entries/:id", async (req, res) => {
    try {
      const db = await getDb();
      const id = req.params.id;
      const title = (req.body?.title ?? "").toString();
      const content = (req.body?.content ?? "").toString().trim();
      if (!content) return sendError(res, 400, "VALIDATION_ERROR", "Nội dung không được rỗng");

      const existing = await db.get("SELECT id, entry_date FROM entries WHERE id = ?", [id]);
      if (!existing) return sendError(res, 404, "NOT_FOUND", "Không tìm thấy bài nhật ký");

      const t = nowMs();
      const entryDate = req.body?.entryDate ?? (existing.entry_date ?? t);
      await db.run(
        "UPDATE entries SET title = ?, content = ?, entry_date = ?, updated_at = ? WHERE id = ?",
        [title, content, entryDate, t, id],
      );

      const entry = await db.get(
        "SELECT id, title, content, entry_date, created_at, updated_at FROM entries WHERE id = ?",
        [id],
      );
      const photos = await db.all(
        "SELECT id, url, created_at FROM photos WHERE entry_id = ? ORDER BY created_at ASC",
        [id],
      );

      res.json({
        data: {
          id: entry.id,
          title: entry.title ?? "",
          content: entry.content,
          entryDate: entry.entry_date ?? entry.created_at,
          createdAt: entry.created_at,
          updatedAt: entry.updated_at,
          photos: photos.map((p) => ({
            id: p.id,
            url: p.url,
            createdAt: p.created_at,
          })),
        },
      });
    } catch (e) {
      sendError(res, 500, "INTERNAL_ERROR", "Lỗi server");
    }
  });

  // Delete entry (and its photos + files)
  app.delete("/api/entries/:id", async (req, res) => {
    try {
      const db = await getDb();
      const id = req.params.id;

      const entry = await db.get("SELECT id FROM entries WHERE id = ?", [id]);
      if (!entry) return sendError(res, 404, "NOT_FOUND", "Không tìm thấy bài nhật ký");

      const photos = await db.all(
        "SELECT id, filename FROM photos WHERE entry_id = ?",
        [id],
      );

      // Delete entry first (cascade removes photos if FK works)
      await db.run("DELETE FROM entries WHERE id = ?", [id]);

      // Remove files on disk (best-effort)
      await Promise.all(
        photos.map(async (p) => {
          const filePath = path.join(UPLOAD_DIR, p.filename);
          try {
            await fs.unlink(filePath);
          } catch (_) {}
        }),
      );

      res.json({ data: null });
    } catch (e) {
      sendError(res, 500, "INTERNAL_ERROR", "Lỗi server");
    }
  });

  // Upload photos
  app.post("/api/entries/:id/photos", upload.array("photos", 10), async (req, res) => {
    try {
      const db = await getDb();
      const entryId = req.params.id;
      const entry = await db.get("SELECT id FROM entries WHERE id = ?", [entryId]);
      if (!entry) return sendError(res, 404, "NOT_FOUND", "Không tìm thấy bài nhật ký");

      const files = req.files ?? [];
      if (!Array.isArray(files) || files.length === 0) {
        return sendError(res, 400, "VALIDATION_ERROR", "Thiếu file ảnh (field: photos)");
      }

      const t = nowMs();
      const created = [];
      for (const f of files) {
        const photoId = makeId();
        const filename = f.filename;
        const url = toPublicUploadUrl(filename);
        await db.run(
          "INSERT INTO photos (id, entry_id, filename, url, created_at) VALUES (?, ?, ?, ?, ?)",
          [photoId, entryId, filename, url, t],
        );
        created.push({ id: photoId, url, createdAt: t });
      }

      res.status(201).json({ data: { photos: created } });
    } catch (e) {
      if (e && typeof e === "object" && e.message === "UNSUPPORTED_MEDIA_TYPE") {
        return sendError(res, 415, "UNSUPPORTED_MEDIA_TYPE", "Chỉ hỗ trợ jpeg/png/webp");
      }
      if (e && typeof e === "object" && e.code === "LIMIT_FILE_SIZE") {
        return sendError(res, 413, "FILE_TOO_LARGE", "File quá lớn");
      }
      sendError(res, 500, "INTERNAL_ERROR", "Lỗi server");
    }
  });

  // Delete photo
  app.delete("/api/photos/:photoId", async (req, res) => {
    try {
      const db = await getDb();
      const photoId = req.params.photoId;

      const photo = await db.get(
        "SELECT id, filename FROM photos WHERE id = ?",
        [photoId],
      );
      if (!photo) return sendError(res, 404, "NOT_FOUND", "Không tìm thấy ảnh");

      await db.run("DELETE FROM photos WHERE id = ?", [photoId]);

      const filePath = path.join(UPLOAD_DIR, photo.filename);
      try {
        await fs.unlink(filePath);
      } catch (_) {}

      res.json({ data: null });
    } catch (e) {
      sendError(res, 500, "INTERNAL_ERROR", "Lỗi server");
    }
  });

  // Multer errors (file too large, etc.)
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    if (err && err.message === "UNSUPPORTED_MEDIA_TYPE") {
      return sendError(res, 415, "UNSUPPORTED_MEDIA_TYPE", "Chỉ hỗ trợ jpeg/png/webp");
    }
    if (err && err.code === "LIMIT_FILE_SIZE") {
      return sendError(res, 413, "FILE_TOO_LARGE", "File quá lớn");
    }
    return sendError(res, 500, "INTERNAL_ERROR", "Lỗi server");
  });

  return app;
}

module.exports = { createApp };

