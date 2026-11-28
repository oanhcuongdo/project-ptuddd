import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import '../providers/momo_fund_provider.dart';
import '../providers/receipt_approval_provider.dart';
import '../utils/saving_streak_calculator.dart';
import 'approve_receipt_screen.dart';
import 'deposit_receipt_sheet.dart';
import 'momo_fund_screen.dart';
import 'screens/saving_plan_screen.dart';
import 'setup_momo_sheet.dart';
import 'widgets/daily_you_streak_calendar.dart';
import 'widgets/module_provider_scope.dart';

/// Route path contract for Module 2 (`saving_discipline_and_momo`).
abstract final class SavingRoutes {
  static const String momoFund = '/trip/momo';
  static const String savingPlan = '/saving-plan';
  static const String momoDeposit = '/momo-deposit';
  static const String streakCalendar = '/streak-calendar';
  static const String momoConfig = '/momo-config';
  static const String pendingReceipts = '/pending-receipts';
  static const String approveReceiptAlias = '/trip/momo/approve';
}

/// Optional route arguments passed via `GoRouterState.extra` or URI query parameters.
class SavingRouteArgs {
  const SavingRouteArgs({
    required this.tripId,
    required this.memberId,
    required this.memberName,
    this.isHost,
    this.targetAmount,
    this.departureDate,
  });

  final String tripId;
  final String memberId;
  final String memberName;
  final bool? isHost;
  final double? targetAmount;
  final DateTime? departureDate;

  factory SavingRouteArgs.fromGoRouterState(
    GoRouterState state, {
    String defaultTripId = 'trip_demo_01',
    String defaultMemberId = 'member_demo_01',
    String defaultMemberName = 'Đỗ Đình An',
  }) {
    final extra = state.extra;
    if (extra is SavingRouteArgs) {
      return extra;
    }

    final query = state.uri.queryParameters;
    final map = extra is Map<String, dynamic> ? extra : const <String, dynamic>{};

    final tripId = (map['tripId'] as String?) ?? query['tripId'] ?? defaultTripId;
    final memberId = (map['memberId'] as String?) ?? query['memberId'] ?? defaultMemberId;
    final memberName =
        (map['memberName'] as String?) ?? query['memberName'] ?? defaultMemberName;

    bool? parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is String) {
        if (val.toLowerCase() == 'true') return true;
        if (val.toLowerCase() == 'false') return false;
      }
      return null;
    }

    return SavingRouteArgs(
      tripId: tripId,
      memberId: memberId,
      memberName: memberName,
      isHost: parseBool(map['isHost'] ?? query['isHost']),
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ??
          double.tryParse(query['targetAmount'] ?? ''),
      departureDate: map['departureDate'] as DateTime?,
    );
  }
}

/// Returns encapsulated `GoRouter` routes for Module 2 ready to spread into the app router.
List<RouteBase> savingModuleRoutes({
  String defaultTripId = 'trip_demo_01',
  String defaultMemberId = 'member_demo_01',
  String defaultMemberName = 'Đỗ Đình An',
}) {
  SavingRouteArgs argsFor(GoRouterState state) => SavingRouteArgs.fromGoRouterState(
        state,
        defaultTripId: defaultTripId,
        defaultMemberId: defaultMemberId,
        defaultMemberName: defaultMemberName,
      );

  return [
    GoRoute(
      path: SavingRoutes.momoFund,
      name: 'saving_momo_fund',
      builder: (context, state) {
        final args = argsFor(state);
        return MomoFundScreen(
          tripId: args.tripId,
          memberId: args.memberId,
          memberName: args.memberName,
          isHost: args.isHost,
        );
      },
    ),
    GoRoute(
      path: SavingRoutes.savingPlan,
      name: 'saving_plan',
      builder: (context, state) {
        final args = argsFor(state);
        return SavingPlanScreen(
          tripId: args.tripId,
          memberId: args.memberId,
          memberName: args.memberName,
          defaultTargetAmount: args.targetAmount ?? 3000000,
          tripDepartureDate: args.departureDate,
        );
      },
    ),
    GoRoute(
      path: SavingRoutes.pendingReceipts,
      name: 'saving_pending_receipts',
      builder: (context, state) {
        final args = argsFor(state);
        return ApproveReceiptScreen(
          tripId: args.tripId,
          reviewerId: args.memberId,
        );
      },
    ),
    GoRoute(
      path: SavingRoutes.approveReceiptAlias,
      name: 'saving_approve_receipt',
      builder: (context, state) {
        final args = argsFor(state);
        return ApproveReceiptScreen(
          tripId: args.tripId,
          reviewerId: args.memberId,
        );
      },
    ),
    GoRoute(
      path: SavingRoutes.streakCalendar,
      name: 'saving_streak_calendar',
      builder: (context, state) {
        final args = argsFor(state);
        return ModuleProviderScope(
          child: Scaffold(
            appBar: AppBar(title: const Text('Lịch chuỗi kỷ luật')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DailyYouStreakCalendar(
                tripId: args.tripId,
                memberId: args.memberId,
              ),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: SavingRoutes.momoConfig,
      name: 'saving_momo_config',
      builder: (context, state) {
        final args = argsFor(state);
        return _SetupMomoRouteScreen(args: args);
      },
    ),
    GoRoute(
      path: SavingRoutes.momoDeposit,
      name: 'saving_momo_deposit',
      builder: (context, state) {
        final args = argsFor(state);
        return _DepositReceiptRouteScreen(args: args);
      },
    ),
  ];
}

class _SetupMomoRouteScreen extends StatelessWidget {
  const _SetupMomoRouteScreen({required this.args});

  final SavingRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _SetupMomoRouteBody(args: args),
    );
  }
}

class _SetupMomoRouteBody extends ConsumerWidget {
  const _SetupMomoRouteBody({required this.args});

  final SavingRouteArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(momoFundStreamProvider(args.tripId)).value;
    final members = ref.watch(tripMembersStreamProvider(args.tripId)).value ?? const [];
    final tripSummary = ref.watch(tripSummaryStreamProvider(args.tripId)).value;
    final realTarget = (tripSummary != null && tripSummary.targetBudget > 0)
        ? tripSummary.targetBudget.toDouble()
        : (args.targetAmount ?? config?.targetTotalAmount ?? 8450000.0);

    return Scaffold(
      body: SafeArea(
        child: SetupMomoSheet(
          tripId: args.tripId,
          hostUserId: config?.hostUserId ?? args.memberId,
          hostName: config?.hostName ?? args.memberName,
          targetTotalAmount: realTarget,
          memberCount: members.isNotEmpty ? members.length : 1,
          initialFrequency:
              config?.defaultFrequency ?? SavingFrequency.weekly,
          initialFundName: config?.fundName ?? 'Quỹ chuyến đi',
          initialPhoneNumber: config?.momoPhoneNumber ?? '',
          initialFundLink: config?.momoFundDeeplink ?? '',
          initialQrCodeUrl: config?.qrCodeUrl,
        ),
      ),
    );
  }
}

class _DepositReceiptRouteScreen extends StatelessWidget {
  const _DepositReceiptRouteScreen({required this.args});

  final SavingRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _DepositReceiptRouteBody(args: args),
    );
  }
}

class _DepositReceiptRouteBody extends ConsumerWidget {
  const _DepositReceiptRouteBody({required this.args});

  final SavingRouteArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(momoFundStreamProvider(args.tripId)).value;
    final plans = ref.watch(tripSavingPlansStreamProvider(args.tripId)).value ?? const [];
    final tripSummary = ref.watch(tripSummaryStreamProvider(args.tripId)).value;
    final members = ref.watch(tripMembersStreamProvider(args.tripId)).value ?? const [];
    final plan = plans.where((p) => p.memberId == args.memberId).firstOrNull;
    final targetAmount = (tripSummary != null && tripSummary.targetBudget > 0)
        ? tripSummary.targetBudget.toDouble()
        : (config?.targetTotalAmount ?? args.targetAmount ?? 0.0);
    final memberCount = members.isNotEmpty
        ? members.length
        : (plans.isNotEmpty ? plans.length : 1);
    final defaults = MoMoFundConfig.resolveDepositDefaults(
      config: config,
      plan: plan,
      targetTotalAmount: targetAmount,
      memberCount: memberCount,
    );

    return Scaffold(
      body: SafeArea(
        child: DepositReceiptSheet(
          tripId: args.tripId,
          memberId: args.memberId,
          memberName: plan?.memberName ?? args.memberName,
          fundName: config?.fundName ?? 'Quỹ nhóm MoMo',
          amount: defaults.amount,
          installmentIndex: defaults.installmentIndex,
          cycleLabel: defaults.cycleLabel,
          termDueDate: plan != null
              ? SavingStreakCalculator.termDueDateForInstallment(
                  plan: plan,
                  installmentIndex: defaults.installmentIndex,
                )
              : null,
          termFrequency: defaults.frequency,
          momoLink: config?.momoFundDeeplink,
          phoneNumber: config?.momoPhoneNumber,
          qrData: config?.qrCodeUrl,
          allowAmountEdit: true,
        ),
      ),
    );
  }
}
