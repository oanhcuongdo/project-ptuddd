import 'package:go_router/go_router.dart';

import '../core/widgets/trip_shell_scaffold.dart';
import '../features/auth_and_group/presentation/create_trip_qr_screen.dart';
import '../features/auth_and_group/presentation/login_screen.dart';
import '../features/auth_and_group/presentation/members_profile_screen.dart';
import '../features/auth_and_group/presentation/trip_list_screen.dart';
import '../features/budget_and_expense_cashew/presentation/add_expense_ocr_screen.dart';
import '../features/budget_and_expense_cashew/presentation/budget_screen.dart';
import '../features/budget_and_expense_cashew/presentation/expense_detail_screen.dart';
import '../features/goal_and_checklist/presentation/checklist_screen.dart';
import '../features/place_and_itinerary_planner/presentation/add_activity_screen.dart';
import '../features/place_and_itinerary_planner/presentation/itinerary_screen.dart';
import '../features/saving_discipline_and_momo/presentation/approve_receipt_screen.dart';
import '../features/saving_discipline_and_momo/presentation/momo_fund_screen.dart';

/// GoRouter nối toàn bộ giao diện prototype của 5 thư mục features.
/// TODO(Module 1): Bổ sung redirect Auth Guard lắng nghe FirebaseAuth.instance.authStateChanges().
final GoRouter appRouterPreview = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/trips',
      builder: (context, state) => const TripListScreen(),
    ),
    GoRoute(
      path: '/trips/create',
      builder: (context, state) => const CreateTripQrScreen(),
    ),
    GoRoute(
      path: '/trip/members',
      builder: (context, state) => const MembersProfileScreen(),
    ),
    GoRoute(
      path: '/trip/momo/approve',
      builder: (context, state) => const ApproveReceiptScreen(),
    ),
    GoRoute(
      path: '/trip/itinerary/add',
      builder: (context, state) => const AddActivityScreen(tripId: 'demo-trip'),
    ),
    GoRoute(
      path: '/trip/budget/add',
      builder: (context, state) => const AddExpenseOcrScreen(),
    ),
    GoRoute(
      path: '/trip/budget/detail',
      builder: (context, state) => const ExpenseDetailScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return TripShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trip/checklist',
              builder: (context, state) => const ChecklistScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trip/momo',
              builder: (context, state) => const MomoFundScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trip/itinerary',
              builder: (context, state) => const ItineraryScreen(tripId: 'demo-trip'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trip/budget',
              builder: (context, state) => const BudgetScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
