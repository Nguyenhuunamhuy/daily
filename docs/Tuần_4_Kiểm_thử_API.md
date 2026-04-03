# Tuần 4 — Kiểm thử API/Function (Backend)

## 1. Môi trường kiểm thử

- **Backend**: Node.js + Express (thư mục `back/`)
- **Database**: SQLite file `back/data/diary.sqlite`
- **Cổng chạy**: `http://localhost:3000`

## 2. Cách chạy backend

Tại thư mục `back/`:

```bash
npm start
```

Kiểm tra nhanh:
- `GET /health` → `{ "data": { "status": "ok" } }`

## 3. Danh sách kịch bản kiểm thử & kết quả

Ghi chú:
- **Expected**: kết quả mong đợi theo đặc tả Tuần 3
- **Actual**: kết quả thực tế sau khi chạy test

### TC01 — Health check

- **Request**: `GET /health`
- **Expected**: 200, JSON `{ data: { status: "ok" } }`
- **Actual**: 200, `{ "data": { "status": "ok" } }`

---

### TC02 — Tạo entry (hợp lệ)

- **Request**: `POST /api/entries`
- **Body**:

```json
{ "title": "Bài test", "content": "Nội dung test" }
```

- **Expected**: 201, trả về `data.id` và timestamps
- **Actual**: 201, tạo thành công (ví dụ id: `935d01d5-42cf-4fba-80cd-09510f7851b8`)

---

### TC03 — Tạo entry (content rỗng)

- **Request**: `POST /api/entries`
- **Body**:

```json
{ "title": "Bài lỗi", "content": "" }
```

- **Expected**: 400 `VALIDATION_ERROR`
- **Actual**: 400 (đúng như mong đợi)

---

### TC04 — List entries (mặc định)

- **Request**: `GET /api/entries`
- **Expected**: 200, có `data.items`, `page/limit/total`
- **Actual**: 200, trả về `data.items` và `total` đúng (sau khi tạo 1 entry thì `total: 1`)

---

### TC05 — Get detail entry (tồn tại)

- **Request**: `GET /api/entries/:id`
- **Expected**: 200, có `photos: []`
- **Actual**: 200, `photos: []` (trước khi upload ảnh)

---

### TC06 — Get detail entry (không tồn tại)

- **Request**: `GET /api/entries/not-exist`
- **Expected**: 404 `NOT_FOUND`
- **Actual**: 404 (đúng như mong đợi)

---

### TC07 — Update entry (hợp lệ)

- **Request**: `PUT /api/entries/:id`
- **Body**:

```json
{ "title": "Bài test (đã sửa)", "content": "Nội dung đã sửa" }
```

- **Expected**: 200, `updatedAt` thay đổi
- **Actual**: 200, `updatedAt` tăng (ví dụ từ `1775228831555` → `1775228890141`)

---

### TC08 — Upload ảnh cho entry

- **Request**: `POST /api/entries/:id/photos`
- **Form-data**: field `photos` (1 file ảnh)
- **Expected**: 201, trả về `data.photos[0].url` có thể truy cập qua `/uploads/...`
- **Actual**: 201, upload thành công (ví dụ photoId: `7a0f3593-6340-49ea-943a-be8bae165963`, url: `/uploads/46a81941-20b5-4bc7-bd17-d5945ada6b9d.png`), truy cập URL trả 200

---

### TC09 — Xoá ảnh

- **Request**: `DELETE /api/photos/:photoId`
- **Expected**: 200 `{ data: null }`
- **Actual**: 200 `{ "data": null }`, kiểm tra URL ảnh sau xoá trả 404

---

### TC10 — Xoá entry

- **Request**: `DELETE /api/entries/:id`
- **Expected**: 200 `{ data: null }`
- **Actual**: 200 `{ "data": null }`, list lại `GET /api/entries` cho `total: 0`

