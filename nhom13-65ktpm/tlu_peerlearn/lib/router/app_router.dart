import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_session_logs_screen.dart';
import '../features/auth_profile/data/auth_repository.dart';
import '../features/auth_profile/domain/program_registration.dart';
import '../features/auth_profile/presentation/course_registration_screen.dart';
import '../features/auth_profile/presentation/login_screen.dart';
import '../features/auth_profile/presentation/profile_screen.dart';
import '../features/auth_profile/presentation/register_screen.dart';
import '../features/auth_profile/presentation/student_home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final profile = profileAsync.value;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (profile == null) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute) {
        return profile.isAdmin ? '/admin' : '/student';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/sessions',
        builder: (context, state) => const AdminSessionLogsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/registrations',
        builder: (context, state) => CourseRegistrationScreen(
          initialRegistration: state.extra as ProgramRegistration?,
        ),
      ),
    ],
  );
});
