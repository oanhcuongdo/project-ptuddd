/// Hằng số tên bảng cho CSDL Supabase Cloud (14 bảng chuẩn 3NF) và SQLite cục bộ.
/// Cả 5 thành viên dùng chung file này để tránh sai tên bảng khi truy vấn.
class DatabaseTables {
  // === 001: Auth, Tài khoản đa phương thức & Hồ sơ (Hưng) ===
  static const String users = 'users';
  static const String userAccounts = 'user_accounts';
  static const String profiles = 'profiles';
  static const String userReports = 'user_reports';

  // === 002: Kỷ luật cá nhân — Streak & Heatmap (Hưng) ===
  static const String dailyGoals = 'daily_goals';
  static const String userQuestLogs = 'user_quest_logs';

  // === 003: Ghép cặp Buddy (Tiến) & Chat 1-1 / Chat Nhóm (Hưng) ===
  static const String buddyMatches = 'buddy_matches';
  static const String conversations = 'conversations';
  static const String conversationMembers = 'conversation_members';
  static const String messages = 'messages';

  // === 004: Chủ đề (Đạo), Buổi luyện tập (Kiên) & Sổ tay từ vựng (Hải) ===
  static const String conversationTopics = 'conversation_topics';
  static const String userTopicProgress = 'user_topic_progress';
  static const String practiceSessions = 'practice_sessions';
  static const String vocabNotebook = 'vocab_notebook';

  // === Tên file & 5 bảng SQLite cục bộ (Offline-First) ===
  static const String localDbName = 'buddytalk_local.db';
  static const int localDbVersion = 2;

  static const String localDailyGoals = 'local_daily_goals';
  static const String localQuestLogs = 'local_quest_logs';
  static const String localVocabNotebook = 'local_vocab_notebook';
  static const String localPracticeSessions = 'local_practice_sessions';
  static const String localTopicProgress = 'local_topic_progress';
}
