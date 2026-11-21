import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/roadmap/presentation/screens/roadmap_screen.dart';
import '../../features/lessons/presentation/screens/lesson_list_screen.dart';
import '../../features/pronunciation/presentation/screens/pronunciation_screen.dart';
import '../../features/writing/presentation/screens/writing_screen.dart';
import '../../features/flashcard/presentation/screens/flashcard_screen.dart';
import '../../features/ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../features/ai_chat/presentation/screens/ai_chat_summary_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppConstants.homeRoute,
  routes: [
    GoRoute(
      path: AppConstants.homeRoute,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppConstants.loginRoute,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.roadmapRoute,
      builder: (context, state) => const RoadmapScreen(),
    ),
    GoRoute(
      path: AppConstants.lessonsRoute,
      builder: (context, state) => const LessonListScreen(),
    ),
    GoRoute(
      path: AppConstants.pronunciationRoute,
      builder: (context, state) => const PronunciationScreen(),
    ),
    GoRoute(
      path: AppConstants.writingRoute,
      builder: (context, state) => const WritingScreen(),
    ),
    GoRoute(
      path: AppConstants.flashcardRoute,
      builder: (context, state) => const FlashcardScreen(),
    ),
    GoRoute(
      path: AppConstants.aiChatRoute,
      // /ai-chat?lessonId=1&title=Chào hỏi
      builder: (context, state) => AiChatScreen(
        lessonId: int.tryParse(state.uri.queryParameters['lessonId'] ?? '') ?? 1,
        lessonTitle: state.uri.queryParameters['title'],
      ),
    ),
    GoRoute(
      path: '${AppConstants.aiChatRoute}/summary/:id',
      builder: (context, state) => AiChatSummaryScreen(conversationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppConstants.statisticsRoute,
      builder: (context, state) => const StatisticsScreen(),
    ),
  ],
);
