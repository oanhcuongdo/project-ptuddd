class AppConstants {
  static const String appName = 'BuddyTalk';
  static const String appTagline = 'Giữ vững kỷ luật – Vượt rào cản ngôn ngữ';

  // Thông tin nhóm & học phần
  static const String groupName = 'Nhóm 09';
  static const String classCode = '65KTPM';
  static const String courseName = 'Phát Triển Ứng Dụng Di Động';
  static const String instructor = 'ThS. Đỗ Cường Oanh';

  // Ngôn ngữ & trình độ hỗ trợ (đồng bộ giữa Auth, Buddy Matching & Topics)
  static const Map<String, String> languageLabels = {
    'vi': 'Tiếng Việt',
    'en': 'English',
    'zh': '中文 (Tiếng Trung)',
  };

  static const List<String> proficiencyLevels = ['A1', 'A2', 'B1', 'B2'];

  // Cấu hình thời gian mặc định cho buổi học (phút)
  static const int defaultSessionMinutes = 20;
}
