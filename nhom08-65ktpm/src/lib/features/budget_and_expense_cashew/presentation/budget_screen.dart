import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_skeleton_loader.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/trip_detail_app_bar.dart';
import '../../../core/widgets/vnd_text_field.dart';
import '../../../models/trip_member.dart';
import '../../auth_and_group/presentation/widgets/trip_members_sheet.dart';
import '../../auth_and_group/providers/auth_providers.dart';
import '../../auth_and_group/providers/trip_providers.dart';
import '../../auth_and_group/repository/auth_repository.dart';
import '../models/budget_envelope.dart';
import '../models/trip_expense.dart';
import '../providers/budget_providers.dart';
import '../utils/debt_simplifier.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  Future<void> _editEnvelopeBudget(
    String tripId,
    BudgetEnvelope envelope,
  ) async {
    final controller = TextEditingController(
      text: VndThousandInputFormatter.formatDigits(
        envelope.allocatedAmount.toString(),
      ),
    );
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ngân sách hũ ${envelope.name}'),
        content: VndTextField(
          controller: controller,
          autofocus: true,
          labelText: 'Số tiền dự kiến (VNĐ)',
          border: const UnderlineInputBorder(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = AppFormatters.parseVnd(controller.text);
              Navigator.pop(context, parsed);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || !mounted) return;
    try {
      await ref
          .read(budgetControllerProvider)
          .updateEnvelopeBudget(
            tripId: tripId,
            envelopeId: envelope.id,
            allocatedAmount: amount,
          );
    } catch (error) {
      _showMessage('Không thể cập nhật ngân sách: $error');
    }
  }

  Future<void> _confirmPayDebt(
    String tripId,
    SimplifiedSettlement settlement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận chốt quyết toán'),
        content: Text(
          'Xác nhận ${settlement.fromName} đã thanh toán '
          '${AppFormatters.formatVnd(settlement.amount)} cho '
          '${settlement.toName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chốt quyết toán'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(budgetControllerProvider)
          .settleDebt(tripId: tripId, settlement: settlement);
      _showMessage('Đã chốt quyết toán thành công.');
    } catch (e) {
      _showMessage('Không thể lưu trạng thái quyết toán: $e');
    }
  }

  Future<void> _createSuggestedEnvelopes(
    String tripId,
    int targetBudget,
  ) async {
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(budgetControllerProvider)
          .initializeEnvelopes(tripId: tripId, targetBudget: targetBudget);
      _showMessage('Đã khởi tạo các hũ ngân sách gợi ý.');
    } catch (e) {
      _showMessage('Không thể khởi tạo hũ ngân sách: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<SimplifiedSettlement> _calculateSettlements(
    List<TripExpense> expenses,
    List<TripMember> members,
  ) {
    final balances = <String, int>{
      for (final member in members) member.userId: 0,
    };
    final names = <String, String>{
      for (final member in members) member.userId: member.displayName,
    };

    for (final expense in expenses.where((item) => item.isPersonalAdvance)) {
      if (expense.paidBy.isEmpty) continue;
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;
      if (expense.paidByName.isNotEmpty) {
        names[expense.paidBy] = expense.paidByName;
      }

      final splits = expense.splitDetails.isNotEmpty
          ? expense.splitDetails
          : _equalSplit(expense.amount, expense.splitBetween);
      for (final entry in splits.entries) {
        balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
      }
    }
    return DebtSimplifier.simplifyNetBalances(balances: balances, names: names);
  }

  Map<String, int> _equalSplit(int amount, List<String> memberIds) {
    if (memberIds.isEmpty) return const {};
    final share = amount ~/ memberIds.length;
    var remainder = amount % memberIds.length;
    return {for (final id in memberIds) id: share + (remainder-- > 0 ? 1 : 0)};
  }

  @override
  Widget build(BuildContext context) {
    final tripId = ref.watch(currentTripIdProvider) ?? 'demo-trip';
    final trip = ref.watch(currentTripProvider).asData?.value;
    final currentUser =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    final memberAsync = ref.watch(currentTripMembersProvider);
    final members = memberAsync.asData?.value ?? const <TripMember>[];
    final targetBudget = trip?.targetBudget ?? 0;
    final memberContributions = members.fold<int>(
      0,
      (total, member) => total + member.contributedAmount,
    );
    final totalCollected = trip != null
        ? (trip.totalSavedAmount > 0
              ? trip.totalSavedAmount
              : memberContributions)
        : memberContributions;
    final streamParams = BudgetStreamParams(
      tripId: tripId,
      targetBudget: targetBudget,
      isHost: trip != null && trip.hostId == currentUser?.uid,
    );
    final envelopeAsync = ref.watch(budgetEnvelopeStreamProvider(streamParams));
    final expensesAsync = ref.watch(budgetExpenseStreamProvider(streamParams));
    final settledMap =
        ref.watch(budgetSettlementStreamProvider(tripId)).asData?.value ??
        const <String, bool>{};

    return Scaffold(
      appBar: TripDetailAppBar(
        title: 'Ngân sách',
        onMembersPressed: () => TripMembersSheet.show(context),
        extraActions: [
          IconButton(
            key: const Key('budget_add_expense_button'),
            tooltip: 'Thêm khoản chi / Quét OCR',
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
            onPressed: () => context.push('/trip/budget/add'),
          ),
        ],
      ),
      body: envelopeAsync.when(
        loading: () => const AppSkeletonLoader(),
        error: (error, _) => _LoadError(
          message: 'Không tải được các hũ ngân sách: $error',
          onRetry: () =>
              ref.invalidate(budgetEnvelopeStreamProvider(streamParams)),
        ),
        data: (envelopes) => expensesAsync.when(
          loading: () => const AppSkeletonLoader(),
          error: (error, _) => _LoadError(
            message: 'Không tải được khoản chi: $error',
            onRetry: () =>
                ref.invalidate(budgetExpenseStreamProvider(streamParams)),
          ),
          data: (expenses) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(budgetEnvelopeStreamProvider(streamParams));
              ref.invalidate(budgetExpenseStreamProvider(streamParams));
              ref.invalidate(budgetSettlementStreamProvider(tripId));
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            child: _buildBudgetContent(
              tripId: tripId,
              envelopes: envelopes,
              expenses: expenses,
              members: members,
              settledMap: settledMap,
              targetBudget: targetBudget,
              totalCollected: totalCollected,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetContent({
    required String tripId,
    required List<BudgetEnvelope> envelopes,
    required List<TripExpense> expenses,
    required List<TripMember> members,
    required Map<String, bool> settledMap,
    required int targetBudget,
    required int totalCollected,
  }) {
    final totalSpent = envelopes.fold<int>(
      0,
      (total, envelope) => total + envelope.spentAmount,
    );
    final totalPlanned = envelopes.fold<int>(
      0,
      (total, envelope) => total + envelope.allocatedAmount,
    );
    final settlements = _calculateSettlements(expenses, members);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        AppInsetCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng thực chi nhóm',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppFormatters.formatVnd(totalSpent),
                style: AppTheme.monoAmount(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              _SummaryLine(
                label: 'Ngân sách dự kiến',
                amount: totalPlanned == 0 ? targetBudget : totalPlanned,
                color: AppColors.primary,
              ),
              _SummaryLine(
                label: 'Tiền đã đóng quỹ',
                amount: totalCollected,
                color: AppColors.momo,
              ),
              _SummaryLine(
                label: 'Thực chi',
                amount: totalSpent,
                color: AppColors.mint,
              ),
              const SizedBox(height: 12),
              _EnvelopeComparisonChart(
                envelopes: envelopes,
                totalCollected: totalCollected,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppSectionHeader(
          title: 'Hũ ngân sách',
          trailing: Text(
            '${envelopes.length} danh mục',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        if (envelopes.isEmpty)
          AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Chưa có hũ ngân sách',
            subtitle:
                'Khởi tạo 6 hũ ngân sách chuẩn (Di chuyển, Lưu trú, Ăn uống, Vé, Mua sắm, Dự phòng) để theo dõi chi tiêu.',
            actionLabel: 'Gợi ý chia hũ ngân sách',
            actionIcon: Icons.auto_awesome,
            onAction: () => _createSuggestedEnvelopes(tripId, targetBudget),
          )
        else
          for (final envelope in envelopes) ...[
            const SizedBox(height: 8),
            _EnvelopeCard(
              envelope: envelope,
              collectedAmount: collectedAmountForEnvelope(
                envelope: envelope,
                envelopes: envelopes,
                totalCollected: totalCollected,
              ),
              onEdit: () => _editEnvelopeBudget(tripId, envelope),
            ),
          ],
        const SizedBox(height: 24),
        AppSectionHeader(
          title: 'Thanh toán tối giản',
          trailing: TextButton(
            key: const Key('budget_simplify_debt_button'),
            onPressed: () {
              _showMessage(
                'Đã tính ${settlements.length} giao dịch quyết toán tối giản.',
              );
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Tính lại'),
          ),
        ),
        AppInsetCard(
          child: settlements.isEmpty
              ? const ListTile(
                  title: Text('Mọi thành viên đã cân bằng công nợ.'),
                )
              : Column(
                  children: [
                    for (var index = 0; index < settlements.length; index++)
                      _SettlementTile(
                        settlement: settlements[index],
                        isPaid:
                            settledMap['${settlements[index].fromId}_${settlements[index].toId}'] ??
                            false,
                        onConfirm: () =>
                            _confirmPayDebt(tripId, settlements[index]),
                        showDivider: index < settlements.length - 1,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 24),
        const AppSectionHeader(title: 'Chi tiêu gần đây'),
        if (expenses.isEmpty)
          AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có khoản chi nào',
            subtitle:
                'Bấm + ở góc trên để thêm khoản chi thủ công hoặc quét hóa đơn OCR.',
            actionLabel: 'Thêm hóa đơn',
            onAction: () => context.push('/trip/budget/add'),
          )
        else
          AppInsetCard(
            child: Column(
              children: [
                for (var index = 0; index < expenses.length; index++)
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.receipt_long,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          expenses[index].title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${expenses[index].paidByName} trả • '
                          '${expenses[index].category} • '
                          '${expenses[index].paymentSource == 'group_fund' ? 'Quỹ chung' : 'Ứng trước'}',
                        ),
                        trailing: Text(
                          AppFormatters.formatVnd(expenses[index].amount),
                          style: AppTheme.monoAmount(),
                        ),
                        onTap: () => context.push(
                          '/trip/budget/detail',
                          extra: expenses[index],
                        ),
                      ),
                      if (index < expenses.length - 1) const Divider(indent: 56),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            AppFormatters.formatVnd(amount),
            style: AppTheme.monoAmount(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EnvelopeComparisonChart extends StatelessWidget {
  const _EnvelopeComparisonChart({
    required this.envelopes,
    required this.totalCollected,
  });

  final List<BudgetEnvelope> envelopes;
  final int totalCollected;

  @override
  Widget build(BuildContext context) {
    final values = <int>[
      for (final envelope in envelopes) ...[
        envelope.allocatedAmount,
        collectedAmountForEnvelope(
          envelope: envelope,
          envelopes: envelopes,
          totalCollected: totalCollected,
        ),
        envelope.spentAmount,
      ],
    ];
    final maxAmount = values.fold<int>(0, math.max);
    final maxY = maxAmount == 0 ? 1.0 : maxAmount.toDouble() * 1.2;
    final width = math.max(360.0, envelopes.length * 70.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dự kiến • Đã góp • Thực chi theo hũ',
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barGroups: [
                  for (var index = 0; index < envelopes.length; index++)
                    BarChartGroupData(
                      x: index,
                      barsSpace: 3,
                      barRods: [
                        _rod(
                          envelopes[index].allocatedAmount,
                          AppColors.primary,
                        ),
                        _rod(
                          collectedAmountForEnvelope(
                            envelope: envelopes[index],
                            envelopes: envelopes,
                            totalCollected: totalCollected,
                          ),
                          AppColors.momo,
                        ),
                        _rod(envelopes[index].spentAmount, AppColors.mint),
                      ],
                    ),
                ],
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= envelopes.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            envelopes[index].name,
                            style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _ChartLegend(color: AppColors.primary, label: 'Dự kiến'),
            _ChartLegend(color: AppColors.momo, label: 'Đã góp'),
            _ChartLegend(color: AppColors.mint, label: 'Thực chi'),
          ],
        ),
      ],
    );
  }

  BarChartRodData _rod(int amount, Color color) => BarChartRodData(
    toY: amount.toDouble(),
    color: color,
    width: 9,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
  );
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _EnvelopeCard extends StatelessWidget {
  const _EnvelopeCard({
    required this.envelope,
    required this.collectedAmount,
    required this.onEdit,
  });

  final BudgetEnvelope envelope;
  final int collectedAmount;
  final VoidCallback onEdit;

  Color _progressColor(double rawRatio) {
    if (rawRatio > 1.0) return AppColors.dangerRed;
    if (rawRatio >= 0.8) return AppColors.terracotta;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final rawRatio = envelope.allocatedAmount == 0
        ? (envelope.spentAmount > 0 ? 1.1 : 0.0)
        : envelope.spentAmount / envelope.allocatedAmount;
    final clampedProgress = rawRatio.clamp(0.0, 1.0);
    final barColor = _progressColor(rawRatio);

    return AppInsetCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: envelope.color.withValues(alpha: 0.12),
                  child: Icon(
                    _iconFor(envelope.iconCode),
                    color: envelope.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    envelope.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  key: Key('budget_edit_${envelope.id}'),
                  tooltip: 'Chỉnh ngân sách ${envelope.name}',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _EnvelopeValue(label: 'Dự kiến', amount: envelope.allocatedAmount),
            _EnvelopeValue(label: 'Đã đóng quỹ', amount: collectedAmount),
            _EnvelopeValue(label: 'Thực chi', amount: envelope.spentAmount),
            _EnvelopeValue(
              label: 'Còn lại',
              amount: envelope.remainingAmount,
              color: envelope.remainingAmount < 0 ? AppColors.error : null,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String code) {
    switch (code) {
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'confirmation_number':
        return Icons.confirmation_number_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'shield':
        return Icons.shield_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

class _EnvelopeValue extends StatelessWidget {
  const _EnvelopeValue({required this.label, required this.amount, this.color});

  final String label;
  final int amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            AppFormatters.formatVnd(amount),
            style: AppTheme.monoAmount(
              fontSize: 12,
              color: color ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementTile extends StatelessWidget {
  const _SettlementTile({
    required this.settlement,
    required this.isPaid,
    required this.onConfirm,
    required this.showDivider,
  });

  final SimplifiedSettlement settlement;
  final bool isPaid;
  final VoidCallback onConfirm;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('${settlement.fromName} trả ${settlement.toName}'),
          subtitle: isPaid
              ? const AppStatusBadge(
                  label: 'Đã tất toán',
                  tone: AppBadgeTone.mint,
                  icon: Icons.check_circle,
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onConfirm,
                    child: const Text(
                      'Chốt quyết toán',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
          trailing: Text(
            AppFormatters.formatVnd(settlement.amount),
            style: AppTheme.monoAmount(
              color: isPaid ? AppColors.onSurfaceVariant : AppColors.onSurface,
            ),
          ),
        ),
        if (showDivider) const Divider(indent: 16),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
