import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_inset_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../models/saving_plan.dart';
import '../../providers/saving_plan_provider.dart';
import '../../utils/momo_deeplink_helper.dart';
import '../../utils/saving_calculator.dart';
import '../widgets/module_notification.dart';
import '../widgets/module_provider_scope.dart';

class SavingPlanScreen extends StatelessWidget {
  final String tripId;
  final String memberId;
  final String memberName;
  final double defaultTargetAmount;
  final DateTime? tripDepartureDate;

  const SavingPlanScreen({
    super.key,
    required this.tripId,
    required this.memberId,
    required this.memberName,
    this.defaultTargetAmount = 3000000,
    this.tripDepartureDate,
  });

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _SavingPlanContent(
        tripId: tripId,
        memberId: memberId,
        memberName: memberName,
        defaultTargetAmount: defaultTargetAmount,
        tripDepartureDate: tripDepartureDate,
      ),
    );
  }
}

class _SavingPlanContent extends ConsumerStatefulWidget {
  final String tripId;
  final String memberId;
  final String memberName;
  final double defaultTargetAmount;
  final DateTime? tripDepartureDate;

  const _SavingPlanContent({
    required this.tripId,
    required this.memberId,
    required this.memberName,
    required this.defaultTargetAmount,
    this.tripDepartureDate,
  });

  @override
  ConsumerState<_SavingPlanContent> createState() => _SavingPlanContentState();
}

class _SavingPlanContentState extends ConsumerState<_SavingPlanContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late DateTime _startDate;
  late DateTime _deadlineDate;
  SavingFrequency _frequency = SavingFrequency.weekly;
  SavingPlanCalculationResult? _calculationPreview;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.defaultTargetAmount.toStringAsFixed(0),
    );
    _startDate = DateTime.now();
    _deadlineDate = widget.tripDepartureDate ?? _startDate.add(const Duration(days: 30));
    _updateCalculationPreview();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateCalculationPreview([double alreadyPaid = 0.0]) {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount > 0 && _deadlineDate.isAfter(_startDate)) {
      setState(() {
        _calculationPreview = SavingCalculator.calculateInstallments(
          targetAmount: amount,
          startDate: _startDate,
          deadlineDate: _deadlineDate,
          preferredFrequency: _frequency,
          alreadyPaidAmount: alreadyPaid,
        );
      });
    } else {
      setState(() => _calculationPreview = null);
    }
  }

  Future<void> _selectDeadlineDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: _startDate.add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) {
      setState(() => _deadlineDate = picked);
      _updateCalculationPreview();
    }
  }

  Future<void> _savePlan() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final params = SavingPlanParams(tripId: widget.tripId, memberId: widget.memberId);

    setState(() => _isSaving = true);
    try {
      await ref.read(savingPlanProvider(params).notifier).createSavingPlan(
            memberName: widget.memberName,
            targetAmount: amount,
            startDate: _startDate,
            deadlineDate: _deadlineDate,
            preferredFrequency: _frequency,
          );
      if (!mounted) return;
      ModuleNotification.success(context, 'Đã lưu kế hoạch tích góp thành công!');
    } catch (e) {
      if (!mounted) return;
      ModuleNotification.error(context, 'Lỗi tạo kế hoạch: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _frequencyLabel(SavingFrequency freq) => switch (freq) {
        SavingFrequency.daily => 'Hàng ngày',
        SavingFrequency.weekly => 'Hàng tuần',
        SavingFrequency.monthly => 'Hàng tháng',
      };

  @override
  Widget build(BuildContext context) {
    final params = SavingPlanParams(tripId: widget.tripId, memberId: widget.memberId);
    final planAsync = ref.watch(savingPlanProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch Tích góp Định kỳ'),
        centerTitle: true,
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không thể tải kế hoạch: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (existingPlan) {
          final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
          final parsedAmount = double.tryParse(amountText) ?? 0.0;
          final effectivePreview = (parsedAmount > 0 && _deadlineDate.isAfter(_startDate))
              ? SavingCalculator.calculateInstallments(
                  targetAmount: parsedAmount,
                  startDate: _startDate,
                  deadlineDate: _deadlineDate,
                  preferredFrequency: _frequency,
                  alreadyPaidAmount: existingPlan?.paidAmount ?? 0.0,
                )
              : _calculationPreview;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (existingPlan != null) ...[
                _buildExistingPlanSummary(existingPlan),
                const SizedBox(height: 24),
              ],
              AppSectionHeader(
                title: existingPlan != null
                    ? 'Điều chỉnh lại kế hoạch'
                    : 'Thiết lập kế hoạch mới',
              ),
              _buildPlanForm(),
              if (effectivePreview != null) ...[
                const SizedBox(height: 24),
                const AppSectionHeader(title: 'Dự kiến chia kỳ đóng'),
                _buildCalculationPreviewCard(effectivePreview),
              ],
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: _isSaving ? 'Đang lưu kế hoạch...' : 'Lưu kế hoạch tích góp',
                icon: Icons.check_circle_outline,
                onPressed: _isSaving ? null : _savePlan,
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExistingPlanSummary(SavingPlan plan) {
    final double progress =
        plan.targetAmount > 0 ? (plan.paidAmount / plan.targetAmount).clamp(0.0, 1.0) : 0.0;
    final isCompleted = plan.status == SavingPlanStatus.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Kế hoạch hiện tại'),
        AppInsetCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          borderColor: isCompleted ? AppColors.mint : AppColors.outlineVariantSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.memberName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppStatusBadge(
                    label: isCompleted ? 'Đã hoàn thành' : 'Đang thực hiện',
                    tone: isCompleted ? AppBadgeTone.mint : AppBadgeTone.primary,
                    icon: isCompleted ? Icons.verified : Icons.timelapse,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                MoMoDeeplinkHelper.formatVnd(plan.paidAmount.round()),
                style: AppTheme.monoAmount(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              Text(
                'Mục tiêu: ${MoMoDeeplinkHelper.formatVnd(plan.targetAmount.round())} • ${(progress * 100).round()}%',
                style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(
                    isCompleted ? AppColors.mint : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tiến độ: ${plan.completedInstallments}/${plan.totalInstallments} kỳ',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${MoMoDeeplinkHelper.formatVnd(plan.installmentAmount.round())} / ${_frequencyLabel(plan.frequency).toLowerCase()}',
                    style: AppTheme.monoAmount(fontSize: 13, color: AppColors.onPrimaryContainer),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanForm() {
    final frequencyIndex = switch (_frequency) {
      SavingFrequency.daily => 0,
      SavingFrequency.weekly => 1,
      SavingFrequency.monthly => 2,
    };

    return Form(
      key: _formKey,
      child: AppInsetCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mục tiêu tích góp cá nhân (VND)',
                suffixText: 'đ',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số tiền';
                final num = double.tryParse(val.trim());
                if (num == null || num <= 0) return 'Số tiền phải lớn hơn 0';
                return null;
              },
              onChanged: (_) => _updateCalculationPreview(),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _selectDeadlineDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariantSoft),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hạn chót hoàn thành (Ngày khởi hành)',
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDate(_deadlineDate)} (Còn ${_deadlineDate.difference(_startDate).inDays} ngày)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chu kỳ đóng quỹ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            AppSegmentedControl(
              segments: const ['Hàng ngày', 'Hàng tuần', 'Hàng tháng'],
              selectedIndex: frequencyIndex,
              onChanged: (index) {
                setState(() {
                  _frequency = switch (index) {
                    0 => SavingFrequency.daily,
                    1 => SavingFrequency.weekly,
                    _ => SavingFrequency.monthly,
                  };
                });
                _updateCalculationPreview();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationPreviewCard(SavingPlanCalculationResult result) {
    final previewItems = result.schedule.take(5).toList();
    return AppInsetCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.totalInstallments} kỳ (${_frequencyLabel(result.frequency)})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${MoMoDeeplinkHelper.formatVnd(result.installmentAmount.round())} / kỳ',
                style: AppTheme.monoAmount(fontSize: 15, color: AppColors.primary),
              ),
            ],
          ),
          if (result.finalInstallmentAmount != result.installmentAmount) ...[
            const SizedBox(height: 6),
            Text(
              'Kỳ cuối điều chỉnh: ${MoMoDeeplinkHelper.formatVnd(result.finalInstallmentAmount.round())} (bù phần dư làm tròn)',
              style: const TextStyle(fontSize: 12, color: AppColors.onAmberContainer),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          ...previewItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.isAdjusted
                          ? AppColors.amberContainer
                          : AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.index}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: item.isAdjusted
                            ? AppColors.onAmberContainer
                            : AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hạn ${_formatDate(item.dueDate)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    MoMoDeeplinkHelper.formatVnd(item.amount.round()),
                    style: AppTheme.monoAmount(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (result.schedule.length > 5) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                '... và ${result.schedule.length - 5} kỳ tiếp theo',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
