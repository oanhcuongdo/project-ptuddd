// Cấu hình kết nối Supabase Cloud cho ứng dụng Quản lý Tài liệu Học tập
// Nhóm 11 - Kiến trúc Phần mềm & Điện toán Đám mây

class SupabaseConfig {
  /// URL dự án Supabase của nhóm
  static const String supabaseUrl = 'https://study-material-nhom11.supabase.co';

  /// Khóa công khai ẩn danh (Anon Key) dùng cho Client
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0dWR5LW1hdGVyaWFsLW5ob20xMSIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzI4NTU0NDAwLCJleHAiOjIwNDQxMzA0MDB9.nhom11_demo_anon_key_mock_secure_token';

  /// Tên Bucket lưu trữ tệp tin trên Supabase Storage (Miễn phí 1GB, không cần thẻ)
  static const String storageBucket = 'study-documents';
}
