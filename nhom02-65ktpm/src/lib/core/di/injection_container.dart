import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../application/reminder_scheduler.dart';
import '../../application/session_service.dart';
import '../../application/tips_cache.dart';
import '../../data/auth/firebase_auth_repository.dart';
import '../../data/firestore/firestore_paths.dart';
import '../../data/firestore/firestore_tip_repository.dart';
import '../../data/firestore/firestore_user_profile_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/tip_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';

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

  // -------------------------------------------------------------
  // 2. Data Sources & Repositories
  // Phụ trách: Phùng Thành An (Issue #5), Nguyễn Hoàng Anh (Issue #4)
  // -------------------------------------------------------------
  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(sl(), GoogleSignIn.instance),
  );
  sl.registerLazySingleton<UserProfileRepository>(() => FirestoreUserProfileRepository(sl()));
  sl.registerLazySingleton<TipRepository>(() => FirestoreTipRepository(sl()));

  // -------------------------------------------------------------
  // 3. Application Use Cases
  // Phụ trách: Phùng Thành An (Issue #5, #7), Nguyễn Hoàng Anh (Issue #8)
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // 4. State / Services dùng chung (ChangeNotifier)
  // -------------------------------------------------------------
  // Bản rỗng; Issue #10 thay bằng lịch nhắc thật (flutter_local_notifications).
  sl.registerLazySingleton<ReminderScheduler>(() => NoopReminderScheduler());
  sl.registerLazySingleton<SessionService>(() => SessionService(sl(), sl(), sl()));
  // Thư viện gợi ý: tạo ngay để tự tải tips khi người dùng đăng nhập.
  sl.registerSingleton<TipsCache>(TipsCache(sl(), sl()));
}
