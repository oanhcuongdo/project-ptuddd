/// Hằng số tên bảng cho CSDL Supabase Cloud và SQLite cục bộ.
/// Cả 5 thành viên dùng chung file này để tránh sai tên bảng khi truy vấn.
class DatabaseTables {
  // === 8 bảng chính trên Supabase Cloud (theo Đề cương TH4) ===
  static const String profiles = 'profiles';
  static const String buddyMatches = 'buddy_matches';
  static const String studyGroups = 'study_groups';
  static const String groupMembers = 'group_members';
  static const String messages = 'messages';
  static const String conversationTopics = 'conversation_topics';
  static const String practiceSessions = 'practice_sessions';
  static const String userQuestLogs = 'user_quest_logs';

  // === Bảng phụ trợ ===
  static const String vocabNotebook = 'vocab_notebook';
  static const String userReports = 'user_reports';

  // === Tên file & bảng SQLite cục bộ (Offline-First) ===
  static const String localDbName = 'buddytalk_local.db';
  static const int localDbVersion = 1;

  static const String localQuestLogs = 'local_quest_logs';
  static const String localVocabNotebook = 'local_vocab_notebook';
  static const String localPracticeSessions = 'local_practice_sessions';
  static const String localTopicProgress = 'local_topic_progress';
}
