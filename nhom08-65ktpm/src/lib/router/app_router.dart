import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/trip_shell_scaffold.dart';
import '../features/auth_and_group/presentation/change_password_screen.dart';
import '../features/auth_and_group/presentation/create_trip_qr_screen.dart';
import '../features/auth_and_group/presentation/edit_profile_screen.dart';
import '../features/auth_and_group/presentation/forgot_password_screen.dart';
import '../features/auth_and_group/presentation/login_screen.dart';
import '../features/auth_and_group/presentation/members_profile_screen.dart';
import '../features/auth_and_group/presentation/profile_screen.dart';
import '../features/auth_and_group/presentation/register_screen.dart';
import '../features/auth_and_group/presentation/trip_list_screen.dart';
import '../features/auth_and_group/presentation/verify_email_screen.dart';
import '../features/auth_and_group/providers/auth_providers.dart';
import '../features/auth_and_group/providers/trip_providers.dart';
import '../features/auth_and_group/repository/auth_repository.dart';
import '../features/budget_and_expense_cashew/models/trip_expense.dart';
import '../features/budget_and_expense_cashew/presentation/add_expense_ocr_screen.dart';
import '../features/budget_and_expense_cashew/presentation/budget_screen.dart';
import '../features/budget_and_expense_cashew/presentation/expense_detail_screen.dart';
import '../features/goal_and_checklist/presentation/checklist_screen.dart';
import '../features/place_and_itinerary_planner/presentation/add_activity_screen.dart';
import '../features/place_and_itinerary_planner/presentation/itinerary_screen.dart';
import '../features/saving_discipline_and_momo/presentation/approve_receipt_screen.dart';
import '../features/saving_discipline_and_momo/presentation/momo_fund_screen.dart';
import '../features/saving_discipline_and_momo/presentation/routes.dart';

/// Route path constants for the Travel Buddy application.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String trips = '/trips';
  static const String createTrip = '/trips/create';
  static const String members = '/trip/members';
  static const String checklist = '/trip/checklist';
  static const String momo = '/trip/momo';
  static const String momoApprove = '/trip/momo/approve';
  static const String itinerary = '/trip/itinerary';
  static const String itineraryAdd = '/trip/itinerary/add';
  static const String budget = '/trip/budget';
  static const String budgetAdd = '/trip/budget/add';
  static const String budgetDetail = '/trip/budget/detail';
}

class _RouterAuthNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

/// Provides the application's [GoRouter] instance with Firebase Auth & Email-Verification guard.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterAuthNotifier();
  ref.listen(authStateProvider, (_, _) => refreshNotifier.refresh());
  ref.onDispose(refreshNotifier.dispose);

  final extraModule2Routes = savingModuleRoutes()
      .where(
        (route) =>
            route is! GoRoute ||
            (route.path != SavingRoutes.momoFund &&
                route.path != SavingRoutes.approveReceiptAlias),
      )
      .toList();

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final user =
          authAsync.asData?.value ??
          ref.read(authRepositoryProvider).currentUser;
      final loc = state.matchedLocation;
      final isPublicAuthRoute =
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword;
      final isVerifyRoute = loc == AppRoutes.verifyEmail;

      if (user == null) {
        return isPublicAuthRoute ? null : AppRoutes.login;
      }

      if (user.isEmailPasswordUser && !user.emailVerified) {
        return isVerifyRoute ? null : AppRoutes.verifyEmail;
      }

      if (isPublicAuthRoute || isVerifyRoute) {
        return AppRoutes.trips;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verify_email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot_password',
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit_profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'change_password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.trips,
        name: 'trips',
        builder: (context, state) => const TripListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createTrip,
        name: 'create_trip',
        builder: (context, state) => const CreateTripQrScreen(),
      ),
      GoRoute(
        path: AppRoutes.members,
        name: 'trip_members',
        builder: (context, state) => const MembersProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.momoApprove,
        name: 'momo_approve_receipt',
        builder: (context, state) => const _LiveApproveReceiptPage(),
      ),
      GoRoute(
        path: AppRoutes.itineraryAdd,
        name: 'itinerary_add',
        builder: (context, state) => const _LiveAddActivityPage(),
      ),
      GoRoute(
        path: AppRoutes.budgetAdd,
        name: 'budget_add',
        builder: (context, state) => const AddExpenseOcrScreen(),
      ),
      GoRoute(
        path: AppRoutes.budgetDetail,
        name: 'budget_detail',
        builder: (context, state) {
          final extra = state.extra;
          return ExpenseDetailScreen(
            expense: extra is TripExpense ? extra : null,
          );
        },
      ),
      ...extraModule2Routes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TripShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.checklist,
                name: 'goal_and_checklist',
                builder: (context, state) => const _LiveChecklistPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.momo,
                name: 'saving_discipline_and_momo',
                builder: (context, state) => const _LiveMomoFundPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.itinerary,
                name: 'place_and_itinerary_planner',
                builder: (context, state) => const _LiveItineraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budget,
                name: 'budget_and_expense_cashew',
                builder: (context, state) => const BudgetScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _LiveChecklistPage extends ConsumerWidget {
  const _LiveChecklistPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = ref.watch(currentTripIdProvider) ?? 'demo-trip';
    return ChecklistScreen(tripId: tripId);
  }
}

class _LiveMomoFundPage extends ConsumerWidget {
  const _LiveMomoFundPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    final trip = ref.watch(currentTripProvider).asData?.value;
    final tripId = ref.watch(currentTripIdProvider) ?? 'demo-trip';
    final memberId = user?.uid ?? 'demo-host-an';
    final memberName = user?.displayName ?? 'Đỗ Đình An';
    final isHost = trip != null ? trip.hostId == memberId : null;

    return MomoFundScreen(
      tripId: tripId,
      memberId: memberId,
      memberName: memberName,
      isHost: isHost,
      tripTargetBudget: trip?.targetBudget.toDouble(),
      tripDepartureDate: trip?.startDate,
      tripMemberCount: trip?.memberIds.length,
    );
  }
}

class _LiveApproveReceiptPage extends ConsumerWidget {
  const _LiveApproveReceiptPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    final tripId = ref.watch(currentTripIdProvider) ?? 'demo-trip';
    return ApproveReceiptScreen(
      tripId: tripId,
      reviewerId: user?.uid ?? 'demo-host-an',
    );
  }
}

class _LiveItineraryPage extends ConsumerWidget {
  const _LiveItineraryPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(currentTripProvider).asData?.value;
    final tripId = ref.watch(currentTripIdProvider) ?? 'demo-trip';
    final days = trip == null
        ? 3
        : (trip.endDate.difference(trip.startDate).inDays + 1).clamp(1, 30);

    return ItineraryScreen(
      tripId: tripId,
      dayCount: days,
      startDate: trip?.startDate,
      destinationName: trip?.destination,
      destinationLat: trip?.destinationLat,
      destinationLng: trip?.destinationLng,
    );
  }
}

class _LiveAddActivityPage extends ConsumerWidget {
  const _LiveAddActivityPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(currentTripProvider).asData?.value;
    final tripId = ref.watch(currentTripIdProvider) ?? 'demo-trip';
    final days = trip == null
        ? 14
        : (trip.endDate.difference(trip.startDate).inDays + 1).clamp(1, 30);
    return AddActivityScreen(
      tripId: tripId,
      dayCount: days,
      defaultLat: trip?.destinationLat,
      defaultLon: trip?.destinationLng,
    );
  }
}
