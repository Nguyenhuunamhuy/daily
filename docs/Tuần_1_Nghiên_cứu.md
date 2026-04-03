# Ứng dụng Nhật ký (có ảnh & tìm kiếm) — Mô tả chức năng (Tuần 1)

## 1. Mục tiêu & phạm vi

Xây dựng một ứng dụng di động **cơ bản nhưng dùng được**, hỗ trợ:

- **Viết nhật ký**: tạo / sửa / xoá bài viết.
- **Đăng ảnh**: mỗi bài nhật ký có thể đính kèm 0~n ảnh.
- **Tìm kiếm**: tìm bài theo từ khoá (tiêu đề / nội dung).

Không làm (có thể mở rộng sau):

- Đăng ký/đăng nhập, nhiều người dùng
- Đồng bộ cloud, đồng bộ offline phức tạp, chia sẻ/bình luận
- Trình soạn thảo rich text nâng cao

## 2. Đối tượng sử dụng & kịch bản

- **Người dùng**
  - **Ghi chép**: viết 1 bài nhật ký, kèm 1~3 ảnh
  - **Xem lại**: duyệt nhật ký theo thời gian
  - **Tìm nhanh**: nhập từ khoá để tìm một bài cụ thể
  - **Quản lý**: chỉnh sửa, xoá bài; xoá ảnh trong bài

## 3. Mô hình dữ liệu cốt lõi (logic)

### 3.1 Bài nhật ký (Entry)

- **id**: định danh duy nhất
- **title**: tiêu đề (có thể rỗng)
- **content**: nội dung (bắt buộc, tối thiểu 1 ký tự)
- **createdAt**: thời điểm tạo
- **updatedAt**: thời điểm cập nhật
- **photos**: danh sách ảnh (0..n)

### 3.2 Ảnh (Photo)

- **id**: định danh duy nhất
- **entryId**: thuộc bài nhật ký nào
- **url**: đường dẫn truy cập ảnh (frontend dùng để hiển thị)
- **filename**: tên file lưu trên server (backend dùng nội bộ)
- **createdAt**: thời điểm upload

## 4. Danh sách chức năng (theo mức ưu tiên)

### 4.1 P0 (bắt buộc)

- **Danh sách nhật ký**
  - Hiển thị theo `createdAt` giảm dần
  - Thông tin: tiêu đề (hoặc 1 dòng đầu nội dung), ngày, ảnh thumbnail (nếu có)
- **Tạo nhật ký mới**
  - Nhập: tiêu đề, nội dung
  - Chọn ảnh: từ thư viện (có thể chọn nhiều)
  - Lưu thành công: quay về danh sách và thấy bài mới
- **Chi tiết nhật ký**
  - Xem tiêu đề, nội dung, ảnh (vuốt xem / dạng lưới)
- **Sửa nhật ký**
  - Sửa tiêu đề/nội dung
  - Thêm ảnh, xoá ảnh
- **Xoá nhật ký**
  - Xác nhận 2 bước
  - Xoá xong danh sách cập nhật
- **Tìm kiếm nhật ký**
  - Từ khoá khớp tiêu đề/nội dung
  - Bấm kết quả → vào chi tiết

### 4.2 P1 (khuyến nghị)

- **Trạng thái rỗng**
  - Danh sách rỗng: gợi ý “Viết bài nhật ký đầu tiên”
  - Tìm kiếm không có kết quả: thông báo + nút xoá từ khoá
- **Loading & thông báo lỗi**
  - Lỗi mạng: hiển thị và cho phép thử lại
  - Upload/Lưu: có loading

### 4.3 P2 (tuỳ chọn)

- Lọc theo ngày (date picker)
- Tag / tâm trạng
- Cache local / xem offline (cache đơn giản)

## 5. Danh sách màn hình chính & điều hướng

### 5.1 Màn hình

- **Trang chủ (danh sách nhật ký)**: `/`
- **Trang tìm kiếm**: `/search`
- **Trang tạo/sửa**: `/editor` (có `id` thì là sửa)
- **Trang chi tiết**: `/detail/:id`

### 5.2 Luồng điều hướng tiêu biểu

- Danh sách → (chọn 1 bài) → Chi tiết
- Danh sách → (bấm +) → Tạo mới → Lưu → Danh sách
- Chi tiết → (bấm sửa) → Sửa → Lưu → Chi tiết
- Danh sách → (bấm tìm kiếm) → Kết quả → Chi tiết

## 6. Yêu cầu phi chức năng (cơ bản)

- **Hiệu năng**: phân trang / tải thêm khi cuộn (backend hỗ trợ page/limit; frontend infinite scroll)
- **Ảnh**: giới hạn upload (ví dụ mỗi ảnh ≤ 5MB; định dạng jpg/png/webp)
- **Bảo mật**: CORS cơ bản; giới hạn thư mục static; random tên file; kiểm tra mimetype
- **Dễ bảo trì**: định nghĩa API rõ ràng (Tuần 3)

