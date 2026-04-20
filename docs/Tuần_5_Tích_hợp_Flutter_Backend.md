# Tuần 5 — Tích hợp Frontend (Flutter) và Backend

## 1. Đã thực hiện

- **Gọi API thật** thay cho dữ liệu giả trong bộ nhớ:
  - Danh sách / chi tiết / tạo / sửa / xoá bài nhật ký
  - Tìm kiếm qua `GET /api/entries?query=...` (debounce 400ms)
- **Upload ảnh**: chọn nhiều ảnh từ thư viện (`image_picker`) → `POST /api/entries/:id/photos` (multipart, field `photos`)
- **Xoá ảnh khi sửa**: so sánh ảnh ban đầu với ảnh hiện tại → `DELETE /api/photos/:id` cho ảnh đã bỏ
- **Cấu hình base URL**: `lib/config/api_config.dart` — có thể ghi đè bằng `--dart-define=API_BASE_URL=...`
- **Android**: thêm `INTERNET` và `usesCleartextTraffic` (HTTP dev)

## 2. Chạy tích hợp

1. Chạy backend (thư mục `back/`):

   ```bash
   npm start
   ```

2. Chạy Flutter:

   - **Windows / máy tính**: mặc định `http://127.0.0.1:3000`
   - **Android Emulator**: dùng `10.0.2.2` thay cho `localhost`:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
   ```

   - **Điện thoại thật (cùng Wi‑Fi)**: đặt `API_BASE_URL` là IP máy chạy Node, ví dụ:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
   ```

## 3. Kịch bản kiểm thử tích hợp (gợi ý)

| # | Kịch bản | Kết quả mong đợi |
|---|----------|------------------|
| 1 | Mở app → danh sách | Gọi `GET /api/entries`, hiển thị bài hoặc trạng thái rỗng / lỗi có nút Thử lại |
| 2 | Kéo xuống làm mới | Gọi lại API, danh sách cập nhật |
| 3 | Tạo mới → nhập nội dung → Lưu | `POST /api/entries`, quay lại danh sách có bài mới |
| 4 | Tạo mới + Thêm ảnh → Lưu | Sau `POST` bài, upload ảnh; danh sách có thumbnail (nếu có ảnh) |
| 5 | Mở chi tiết | `GET /api/entries/:id`, hiển thị nội dung + ảnh |
| 6 | Sửa → bỏ một ảnh cũ → Lưu | `DELETE` ảnh đã xoá, `PUT` bài, upload ảnh mới (nếu có) |
| 7 | Xoá bài từ menu | `DELETE /api/entries/:id`, quay lại danh sách |
| 8 | Tìm kiếm | Gõ từ khoá → kết quả khớp API |

Ghi **kết quả thực tế** (Pass/Fail, ghi chú môi trường) khi nộp bài.
