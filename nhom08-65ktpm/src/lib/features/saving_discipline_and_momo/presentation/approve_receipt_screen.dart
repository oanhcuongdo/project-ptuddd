import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/deposit_record.dart';
import '../providers/receipt_approval_provider.dart';
import '../utils/momo_deeplink_helper.dart';
import 'widgets/module_notification.dart';
import 'widgets/module_provider_scope.dart';

/// Màn hình Duyệt Biên Lai Nạp Quỹ (Dành cho Trưởng nhóm / Fund Host).
class ApproveReceiptScreen extends StatelessWidget {
  const ApproveReceiptScreen({
    super.key,
    this.tripId = 'trip_demo_01',
    this.reviewerId = 'member_demo_01',
  });

  final String tripId;
  final String reviewerId;

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _ApproveReceiptContent(
        tripId: tripId,
        reviewerId: reviewerId,
      ),
    );
  }
}

class _ApproveReceiptContent extends ConsumerStatefulWidget {
  const _ApproveReceiptContent({
    required this.tripId,
    required this.reviewerId,
  });

  final String tripId;
  final String reviewerId;

  @override
  ConsumerState<_ApproveReceiptContent> createState() => _ApproveReceiptContentState();
}

class _ApproveReceiptContentState extends ConsumerState<_ApproveReceiptContent> {
  int _filterIndex = 0; // 0: Chờ duyệt | 1: Đã duyệt | 2: Từ chối
  final Set<String> _processingIds = <String>{};

  Future<void> _approve(DepositRecord record) async {
    if (_processingIds.contains(record.id)) return;
    setState(() => _processingIds.add(record.id));
    try {
      await ref.read(receiptApprovalProvider(widget.tripId).notifier).approveDeposit(
            depositId: record.id,
            reviewerId: widget.reviewerId,
          );
      if (!mounted) return;
      final formatted = MoMoDeeplinkHelper.formatVnd(record.amount.round());
      ModuleNotification.success(
        context,
        'Đã xác nhận biên lai của ${record.memberName} (+$formatted)',
      );
    } catch (e) {
      if (!mounted) return;
      ModuleNotification.error(context, 'Không thể duyệt biên lai: $e');
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(record.id));
      }
    }
  }

  Future<void> _rejectWithReason(DepositRecord record) async {
    if (_processingIds.contains(record.id)) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectReasonDialog(),
    );

    if (reason == null || !mounted) return;
    setState(() => _processingIds.add(record.id));
    try {
      await ref.read(receiptApprovalProvider(widget.tripId).notifier).rejectDeposit(
            depositId: record.id,
            reviewerId: widget.reviewerId,
            reason: reason.isEmpty ? null : reason,
          );
      if (!mounted) return;
      ModuleNotification.info(context, 'Đã từ chối biên lai của ${record.memberName}');
    } catch (e) {
      if (!mounted) return;
      ModuleNotification.error(context, 'Không thể từ chối biên lai: $e');
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(record.id));
      }
    }
  }

  void _openFullScreenViewer(DepositRecord record) {
    final imageUrl = record.receiptImageUrl;
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      ModuleNotification.warning(context, 'Giao dịch này chưa đính kèm ảnh biên lai.');
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: _ReceiptImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholderSize: 96,
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${record.memberName} • ${MoMoDeeplinkHelper.formatVnd(record.amount.round())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m • $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final depositsAsync = ref.watch(tripDepositsStreamProvider(widget.tripId));
    final allDeposits = depositsAsync.value ?? const <DepositRecord>[];
    final pendingCount =
        allDeposits.where((r) => r.status == DepositStatus.pending).length;

    final targetStatus = switch (_filterIndex) {
      0 => DepositStatus.pending,
      1 => DepositStatus.approved,
      _ => DepositStatus.rejected,
    };
    final filteredList =
        allDeposits.where((r) => r.status == targetStatus).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.onPrimaryContainer, size: 28),
          onPressed: () {
            final router = GoRouter.maybeOf(context);
            if (router != null && router.canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text('Duyệt biên lai ($pendingCount)'),
      ),
      body: depositsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không thể tải danh sách biên lai: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSegmentedControl(
              segments: ['Chờ duyệt ($pendingCount)', 'Đã duyệt', 'Từ chối'],
              selectedIndex: _filterIndex,
              onChanged: (i) => setState(() => _filterIndex = i),
            ),
            const SizedBox(height: 16),
            if (filteredList.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: AppInsetCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 36,
                        color: AppColors.onSurfaceVariant,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Không có biên lai nào trong mục này.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredList.map((record) {
                final isProcessing = _processingIds.contains(record.id);
                final cycleText = record.installmentIndex > 0
                    ? 'Kỳ ${record.installmentIndex}'
                    : 'Nạp quỹ';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AppInsetCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryContainer,
                              child: Text(
                                MoMoDeeplinkHelper.formatInitials(record.memberName),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.memberName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$cycleText • ${_formatDateTime(record.depositDate)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              MoMoDeeplinkHelper.formatVnd(record.amount.round()),
                              style: AppTheme.monoAmount(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.momo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.outlineVariantSoft),
                        const SizedBox(height: 12),

                        // Khung xem trước ảnh biên lai MoMo
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openFullScreenViewer(record),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outlineVariantSoft),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 48,
                                    height: 56,
                                    child: _ReceiptImage(
                                      imageUrl: record.receiptImageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mã GD: ${record.id}',
                                        style: AppTheme.monoAmount(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${record.emotionTag ?? '💬'} ${record.note ?? 'Không có ghi chú'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Phóng to biên lai',
                                  icon: const Icon(Icons.zoom_in, color: AppColors.primary),
                                  onPressed: () => _openFullScreenViewer(record),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (record.status == DepositStatus.rejected &&
                            record.rejectionReason != null &&
                            record.rejectionReason!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: AppColors.onErrorContainer,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Lý do từ chối: ${record.rejectionReason}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        if (record.status == DepositStatus.pending)
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed:
                                      isProcessing ? null : () => _rejectWithReason(record),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.errorContainer,
                                    foregroundColor: AppColors.onErrorContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Từ chối'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: isProcessing ? null : () => _approve(record),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.mint,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: isProcessing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Xác nhận hợp lệ'),
                                ),
                              ),
                            ],
                          )
                        else
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppStatusBadge(
                              label: record.status == DepositStatus.approved
                                  ? 'Đã xác nhận'
                                  : 'Đã từ chối',
                              tone: record.status == DepositStatus.approved
                                  ? AppBadgeTone.mint
                                  : AppBadgeTone.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ReceiptImage extends StatelessWidget {
  const _ReceiptImage({
    required this.imageUrl,
    required this.fit,
    this.placeholderSize = 24,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double placeholderSize;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.momoContainer,
        alignment: Alignment.center,
        child: Icon(Icons.receipt_long, color: AppColors.momo, size: placeholderSize),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.momoContainer,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, color: AppColors.momo, size: placeholderSize),
        ),
      );
    }

    final file = File(url);
    if (file.existsSync()) {
      return Image.file(file, fit: fit);
    }

    return Container(
      color: AppColors.momoContainer,
      alignment: Alignment.center,
      child: Icon(Icons.receipt_long, color: AppColors.momo, size: placeholderSize),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Từ chối biên lai'),
      content: TextField(
        controller: _reasonCtrl,
        decoration: const InputDecoration(
          hintText: 'Nhập lý do (VD: Ảnh mờ, thiếu mã giao dịch...)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(context, _reasonCtrl.text.trim()),
          child: const Text('Từ chối'),
        ),
      ],
    );
  }
}
