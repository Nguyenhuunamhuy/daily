class DiaryPhotoEntry {
  const DiaryPhotoEntry({required this.id, required this.url});

  /// Rỗng nếu chỉ có URL hiển thị (ví dụ thumbnail từ danh sách) chưa có id server.
  final String id;
  final String url;
}
