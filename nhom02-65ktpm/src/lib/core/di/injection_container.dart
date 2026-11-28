import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../application/analyze_food_text.dart';
import '../../application/analyze_meal_photo.dart';
import '../../application/confirm_and_save_meal.dart';
import '../../application/meal_events.dart';
import '../../application/meal_queries.dart';
import '../../application/meal_trash_actions.dart';
import '../../application/relog_meal.dart';
import '../../application/reminder_scheduler.dart';
import '../../application/session_service.dart';
import '../../application/tip_resolver.dart';
import '../../application/tips_cache.dart';
import '../../data/ai/ai_analysis_service.dart';
import '../../data/ai/gemini_client.dart';
import '../../data/ai/image_preparer.dart';
import '../../data/ai/rate_limiter.dart';
import '../../data/auth/firebase_auth_repository.dart';
import '../../data/firestore/firestore_favorite_repository.dart';
import '../../data/firestore/firestore_meal_repository.dart';
import '../../data/firestore/firestore_paths.dart';
import '../../data/firestore/firestore_tip_repository.dart';
import '../../data/firestore/firestore_user_profile_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/repositories/tip_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../constants/app_config.dart';

final sl = GetIt.instance; // sl = Service Locator

/// Hàm khởi tạo Dependency Injection cho toàn ứng dụng
Future<void> initDependencies() async {
  // -------------------------------------------------------------
  // 1. External & Backend (Firebase, App Check, Local Storage)
  // Phụ trách: Phạm Văn Việt (Issue #3)
  // -------------------------------------------------------------
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirestorePaths>(() => FirestorePaths(sl()));
  // Firebase AI Logic với provider Gemini Developer API (chạy được trên gói Spark).
  sl.registerLazySingleton<FirebaseAI>(() => FirebaseAI.googleAI());

  // -------------------------------------------------------------
  // 2. Data Sources & Repositories
  // Phụ trách: Phùng Thành An (Issue #5), Nguyễn Hoàng Anh (Issue #4)
  // -------------------------------------------------------------
  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(sl(), GoogleSignIn.instance),
  );
  sl.registerLazySingleton<UserProfileRepository>(() => FirestoreUserProfileRepository(sl()));
  sl.registerLazySingleton<TipRepository>(() => FirestoreTipRepository(sl()));
  sl.registerLazySingleton<MealRepository>(() => FirestoreMealRepository(sl()));
  sl.registerLazySingleton<FavoriteRepository>(() => FirestoreFavoriteRepository(sl()));
  sl.registerLazySingleton<RateLimiter>(
    () => RateLimiter(maxCalls: AppConfig.maxAiCallsPerMinute),
  );
  sl.registerLazySingleton<GeminiClient>(() => GeminiClient(sl(), sl()));
  sl.registerLazySingleton<AiAnalysisService>(() => AiAnalysisService(sl()));
  sl.registerLazySingleton<ImagePreparer>(() => ImagePreparer());

  // -------------------------------------------------------------
  // 3. Application Use Cases
  // Phụ trách: Phùng Thành An (Issue #5, #7), Nguyễn Hoàng Anh (Issue #8)
  // -------------------------------------------------------------
  sl.registerLazySingleton<MealEvents>(() => MealEvents());
  sl.registerLazySingleton<TipResolver>(() => TipResolver(sl(), sl()));
  sl.registerLazySingleton<MealQueries>(() => MealQueries(sl(), sl(), sl()));
  sl.registerLazySingleton<ConfirmAndSaveMeal>(() => ConfirmAndSaveMeal(sl(), sl(), sl(), sl()));
  sl.registerLazySingleton<RelogMeal>(() => RelogMeal(sl(), sl()));
  sl.registerLazySingleton<MealTrashActions>(() => MealTrashActions(sl(), sl(), sl()));
  sl.registerLazySingleton<AnalyzeMealPhoto>(() => AnalyzeMealPhoto(sl(), sl(), sl(), sl()));
  sl.registerLazySingleton<AnalyzeFoodText>(() => AnalyzeFoodText(sl(), sl(), sl(), sl()));

  // -------------------------------------------------------------
  // 4. State / Services dùng chung (ChangeNotifier)
  // -------------------------------------------------------------
  // Bản rỗng; Issue #10 thay bằng lịch nhắc thật (flutter_local_notifications).
  sl.registerLazySingleton<ReminderScheduler>(() => NoopReminderScheduler());
  sl.registerLazySingleton<SessionService>(() => SessionService(sl(), sl(), sl()));
  // Thư viện gợi ý: tạo ngay để tự tải tips khi người dùng đăng nhập.
  sl.registerSingleton<TipsCache>(TipsCache(sl(), sl()));
}
