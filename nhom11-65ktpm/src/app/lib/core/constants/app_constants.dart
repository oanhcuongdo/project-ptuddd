class AppConstants {
  static const String appName = 'ChaiLish';
  static const String appVersion = '1.0.0';
  
  // Base API configuration
  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator default
  static const String webBaseUrl = 'http://localhost:8000/api';
  
  // Storage keys
  static const String tokenKey = 'chailish_access_token';
  static const String refreshTokenKey = 'chailish_refresh_token';
  static const String userIdKey = 'chailish_user_id';
  static const String userEmailKey = 'chailish_user_email';
  
  // Route names
  static const String homeRoute = '/';
  static const String loginRoute = '/auth/login';
  static const String registerRoute = '/auth/register';
  static const String roadmapRoute = '/roadmap';
  static const String lessonsRoute = '/lessons';
  static const String pronunciationRoute = '/pronunciation';
  static const String writingRoute = '/writing';
  static const String flashcardRoute = '/flashcard';
  static const String aiChatRoute = '/ai-chat';
  static const String statisticsRoute = '/statistics';
}
