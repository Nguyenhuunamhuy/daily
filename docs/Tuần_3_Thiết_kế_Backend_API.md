# Tuần 3 — Thiết kế Backend (API/Function) cho Ứng dụng Nhật ký

## 1. Tổng quan kiến trúc (đề xuất)

- **Backend**: Node.js + Express (phù hợp thư mục `back/` hiện tại)
- **Database**: SQLite (file local) — đơn giản, dễ demo/triển khai
- **Lưu ảnh**: upload bằng `multipart/form-data`, lưu file vào thư mục `uploads/`, trả về URL để Flutter hiển thị
- **Base URL (dev)**: `http://localhost:3000`
- **Static files**: `GET /uploads/<filename>` để tải ảnh

> Tuần 3 chỉ thiết kế. Tuần 4 sẽ code theo đúng đặc tả này.

## 2. Mapping API ↔ Màn hình Flutter

- **HomePage (Danh sách nhật ký)**:
  - `GET /api/entries`
- **SearchPage (Tìm kiếm)**:
  - `GET /api/entries?query=...` (hoặc `GET /api/search?query=...`)
- **DetailPage (Chi tiết)**:
  - `GET /api/entries/:id`
  - `DELETE /api/entries/:id`
  - `DELETE /api/photos/:photoId`
- **EditorPage (Tạo/Sửa)**:
  - `POST /api/entries` (tạo)
  - `PUT /api/entries/:id` (sửa)
  - `POST /api/entries/:id/photos` (upload ảnh)

## 3. Danh sách API/Function chính (tên + mục đích)

### 3.1 Entries (bài nhật ký)

- **List entries** — Lấy danh sách bài, có phân trang và tìm kiếm
  - `GET /api/entries`
- **Get entry detail** — Lấy chi tiết 1 bài (kèm ảnh)
  - `GET /api/entries/:id`
- **Create entry** — Tạo bài mới
  - `POST /api/entries`
- **Update entry** — Cập nhật tiêu đề/nội dung
  - `PUT /api/entries/:id`
- **Delete entry** — Xoá bài (và ảnh liên quan)
  - `DELETE /api/entries/:id`

### 3.2 Photos (ảnh)

- **Upload photo(s)** — Upload ảnh cho 1 bài
  - `POST /api/entries/:id/photos`
- **Delete photo** — Xoá 1 ảnh (file + record DB)
  - `DELETE /api/photos/:photoId`

### 3.3 Health/Meta (tuỳ chọn nhưng hữu ích)

- **Health check** — Kiểm tra server chạy
  - `GET /health`

## 4. Thiết kế Database (SQLite)

### 4.0 Quan hệ dữ liệu (ERD đơn giản)

- **entries (1) — (n) photos**
  - 1 bài nhật ký có thể có 0..n ảnh
  - Mỗi ảnh thuộc đúng 1 bài nhật ký qua `photos.entry_id`

Quy ước thời gian:
- `created_at`, `updated_at` lưu dạng **Unix time (milliseconds)** để dễ map sang Flutter (`DateTime.fromMillisecondsSinceEpoch`).

### 4.1 Bảng `entries`

| Cột | Kiểu | Bắt buộc | Ghi chú |
|---|---|---:|---|
| id | TEXT | ✅ | UUID hoặc string tăng dần |
| title | TEXT | ❌ | có thể rỗng |
| content | TEXT | ✅ | nội dung bài |
| created_at | INTEGER | ✅ | unix ms |
| updated_at | INTEGER | ✅ | unix ms |

Index đề xuất:
- `idx_entries_created_at` trên `created_at` (sắp xếp nhanh)
- (Tuỳ chọn) `idx_entries_title_content` nếu dùng FTS (nâng cao)

### 4.2 Bảng `photos`

| Cột | Kiểu | Bắt buộc | Ghi chú |
|---|---|---:|---|
| id | TEXT | ✅ | UUID/string |
| entry_id | TEXT | ✅ | FK tới entries.id |
| filename | TEXT | ✅ | tên file trên server |
| url | TEXT | ✅ | `/uploads/<filename>` hoặc full URL |
| created_at | INTEGER | ✅ | unix ms |

Ràng buộc:
- `photos.entry_id` tham chiếu `entries.id`
- Khi xoá entry → xoá toàn bộ photos (cascade ở mức logic hoặc FK)

### 4.3 SQL Schema tham chiếu (dùng để triển khai Tuần 4)

Nội dung dưới đây tương ứng với file `back/schema.sql`:

```sql
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
```

Ghi chú triển khai:
- Bật `PRAGMA foreign_keys = ON;` để ràng buộc FK/cascade hoạt động trong SQLite.
- Khi xoá entry, nếu cascade không bật, backend vẫn phải xoá `photos` + xoá file ảnh để tránh rác dữ liệu.

## 5. Chuẩn response & lỗi (thống nhất)

### 5.1 Response thành công

- JSON, UTF-8
- Trả về dữ liệu theo dạng:
  - `{ "data": ... }` cho object/list
  - `{ "data": null }` cho delete

### 5.2 Response lỗi

- `{ "error": { "code": "SOME_CODE", "message": "..." } }`

Code lỗi gợi ý:
- `VALIDATION_ERROR` (400)
- `NOT_FOUND` (404)
- `FILE_TOO_LARGE` (413)
- `UNSUPPORTED_MEDIA_TYPE` (415)
- `INTERNAL_ERROR` (500)

## 6. Đặc tả chi tiết từng API

### 6.1 `GET /health`

- **Mục đích**: kiểm tra server
- **Input**: none
- **Output 200**:
  - `{ "data": { "status": "ok" } }`

---

### 6.2 `GET /api/entries`

- **Mục đích**: lấy danh sách bài, hỗ trợ tìm kiếm + phân trang
- **Dùng cho**: HomePage, SearchPage
- **Query params**:
  - `page` (number, default 1)
  - `limit` (number, default 20, max 100)
  - `query` (string, optional) — tìm trong `title` và `content`
- **Output 200**:
  - `data.items`: danh sách entry rút gọn
  - `data.page`, `data.limit`, `data.total`

Ví dụ:

```json
{
  "data": {
    "items": [
      {
        "id": "123",
        "title": "Đi dạo buổi tối",
        "contentPreview": "Trời mát, mình đi dạo...",
        "createdAt": 1712090000000,
        "updatedAt": 1712090000000,
        "coverPhotoUrl": "/uploads/abc.jpg",
        "photoCount": 2
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 42
  }
}
```

- **DB**:
  - `entries` (select)
  - `photos` (đếm và lấy cover photo theo `entry_id`)

---

### 6.3 `GET /api/entries/:id`

- **Mục đích**: lấy chi tiết 1 bài (kèm danh sách ảnh)
- **Dùng cho**: DetailPage
- **Path params**:
  - `id`: entry id
- **Output 200**:

```json
{
  "data": {
    "id": "123",
    "title": "Đi dạo buổi tối",
    "content": "Trời mát...",
    "createdAt": 1712090000000,
    "updatedAt": 1712090000000,
    "photos": [
      { "id": "p1", "url": "/uploads/a.jpg", "createdAt": 1712090100000 },
      { "id": "p2", "url": "/uploads/b.jpg", "createdAt": 1712090200000 }
    ]
  }
}
```

- **Output 404**: `NOT_FOUND`
- **DB**:
  - `entries` by id
  - `photos` by entry_id

---

### 6.4 `POST /api/entries`

- **Mục đích**: tạo bài nhật ký mới
- **Dùng cho**: EditorPage (tạo)
- **Body (JSON)**:
  - `title` (string, optional)
  - `content` (string, required, non-empty)
- **Output 201**:

```json
{
  "data": {
    "id": "124",
    "title": "",
    "content": "Nội dung...",
    "createdAt": 1712091000000,
    "updatedAt": 1712091000000,
    "photos": []
  }
}
```

- **Validation**:
  - `content` rỗng → 400 `VALIDATION_ERROR`
- **DB**:
  - insert `entries`

---

### 6.5 `PUT /api/entries/:id`

- **Mục đích**: cập nhật tiêu đề/nội dung bài
- **Dùng cho**: EditorPage (sửa)
- **Path params**:
  - `id`
- **Body (JSON)**:
  - `title` (string, optional)
  - `content` (string, required, non-empty)
- **Output 200**: trả entry sau cập nhật (kèm photos)
- **Output 404**: `NOT_FOUND`
- **DB**:
  - update `entries`

---

### 6.6 `DELETE /api/entries/:id`

- **Mục đích**: xoá bài nhật ký và toàn bộ ảnh liên quan
- **Dùng cho**: DetailPage
- **Output 200**:

```json
{ "data": null }
```

- **Output 404**: `NOT_FOUND`
- **DB + Files**:
  - select photos theo `entry_id` → xoá file vật lý
  - delete photos
  - delete entry

---

### 6.7 `POST /api/entries/:id/photos`

- **Mục đích**: upload 1 hoặc nhiều ảnh cho entry
- **Dùng cho**: EditorPage
- **Path params**:
  - `id`
- **Request**: `multipart/form-data`
  - field name: `photos` (cho phép nhiều file)
- **Giới hạn đề xuất**:
  - max 10 files / request
  - max 5MB / file
  - mimetype: `image/jpeg`, `image/png`, `image/webp`
- **Output 201**:

```json
{
  "data": {
    "photos": [
      { "id": "p10", "url": "/uploads/xyz.jpg", "createdAt": 1712092000000 }
    ]
  }
}
```

- **Output 404**: `NOT_FOUND` (nếu entry không tồn tại)
- **DB + Files**:
  - lưu file vào `uploads/`
  - insert `photos`

---

### 6.8 `DELETE /api/photos/:photoId`

- **Mục đích**: xoá 1 ảnh khỏi bài
- **Dùng cho**: EditorPage (xoá ảnh), DetailPage (xoá ảnh)
- **Path params**:
  - `photoId`
- **Output 200**:
  - `{ "data": null }`
- **Output 404**: `NOT_FOUND`
- **DB + Files**:
  - select photo by id → xoá file → delete record

## 7. Ghi chú triển khai (để Tuần 4 code đúng)

- **CORS**: cho phép Flutter dev origin
- **Static uploads**: `app.use('/uploads', express.static('uploads'))`
- **Chuẩn hoá URL ảnh**:
  - DB lưu `filename`
  - API trả `url` dạng `/uploads/<filename>` (frontend ghép baseUrl)
- **Search**:
  - Bản cơ bản: `LIKE %query%` trên title/content
  - (Nâng cao) SQLite FTS5 khi cần

