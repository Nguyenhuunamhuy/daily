const path = require("path");
const crypto = require("crypto");

function nowMs() {
  return Date.now();
}

function makeId() {
  return crypto.randomUUID();
}

function toPublicUploadUrl(filename) {
  return `/uploads/${encodeURIComponent(filename)}`;
}

/** Chuẩn hóa MIME (bỏ tham số như "; charset=binary"). */
function normalizeMime(mime) {
  if (!mime || typeof mime !== "string") return "";
  return mime.split(";")[0].trim().toLowerCase();
}

function safeExtFromMime(mime) {
  switch (normalizeMime(mime)) {
    case "image/jpeg":
    case "image/jpg":
    case "image/pjpeg":
      return ".jpg";
    case "image/png":
    case "image/x-png":
      return ".png";
    case "image/webp":
      return ".webp";
    default:
      return null;
  }
}

/** Khi client gửi application/octet-stream hoặc MIME lạ (Flutter/Android), nhận diện qua đuôi file. */
function safeExtFromOriginalName(filename) {
  if (!filename || typeof filename !== "string") return null;
  const ext = path.extname(filename).toLowerCase();
  if (ext === ".jpg" || ext === ".jpeg") return ".jpg";
  if (ext === ".png") return ".png";
  if (ext === ".webp") return ".webp";
  return null;
}

function safeExtForUpload(mime, originalname) {
  return safeExtFromMime(mime) ?? safeExtFromOriginalName(originalname);
}

function basenameNoExt(filename) {
  return path.basename(filename, path.extname(filename));
}

module.exports = {
  nowMs,
  makeId,
  toPublicUploadUrl,
  safeExtFromMime,
  safeExtForUpload,
  basenameNoExt,
};

