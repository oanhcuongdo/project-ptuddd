class AppConstants {
  static const String appName = 'DCSleep';
  static const String appTagline = 'Kỷ luật giấc ngủ & Trợ lý AI thông minh';
  static const String appVersion = '1.0.0';

  // Default sleep goal values
  static const int defaultBedtimeHour = 23;
  static const int defaultBedtimeMinute = 0;
  static const int defaultWakeHour = 7;
  static const int defaultWakeMinute = 0;
  static const double defaultTargetDurationHours = 8.0;

  // Power nap presets (minutes)
  static const List<int> napPresetsMinutes = [10, 15, 20, 30];

  // Database
  static const String dbName = 'dcsleep.db';
  static const int dbVersion = 2;

  // Tables
  static const String tableUsers = 'users';
  static const String tableSleepGoals = 'sleep_goals';
  static const String tableSleepRecords = 'sleep_records';
  static const String tableNapRecords = 'nap_records';
  static const String tableReminders = 'reminders';
  static const String tableAIConversations = 'ai_conversations';
}
