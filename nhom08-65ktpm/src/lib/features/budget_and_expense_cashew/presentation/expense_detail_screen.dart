import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../auth_and_group/providers/trip_providers.dart';
import '../models/trip_expense.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, this.expense});

  final TripExpense? expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentExpense = expense;
    if (currentExpense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khoản chi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Không tìm thấy khoản chi',
              subtitle: 'Hãy chọn một khoản chi từ danh sách hoặc thêm hóa đơn mới.',
              actionLabel: 'Thêm khoản chi',
              onAction: () => context.push('/trip/budget/add'),
            ),
          ),
        ),
      );
    }

    final members =
        ref.watch(currentTripMembersProvider).asData?.value ?? const [];
    final memberNames = {
      for (final member in members) member.userId: member.displayName,
    };
    final splitEntries = currentExpense.splitDetails.entries.toList();
    final receiptUrl = currentExpense.receiptImageUrl;
    final spentAt = currentExpense.spentAt;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            'Đóng',
            style: TextStyle(color: AppColors.onPrimaryContainer),
          ),
        ),
        leadingWidth: 68,
        title: const Text('Chi tiết khoản chi'),
        actions: [
          TextButton(
            onPressed: () => context.push('/trip/budget/add'),
            child: const Text(
              'Thêm khoản chi',
              style: TextStyle(color: AppColors.onPrimaryContainer),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: receiptUrl == null
                      ? null
                      : () => FullScreenImageViewer.open(
                          context,
                          imageUrl: receiptUrl,
                          title: currentExpense.title,
                        ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: receiptUrl == null
                          ? const ColoredBox(
                              color: AppColors.surfaceContainerLow,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 42,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Chưa có ảnh hóa đơn',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Image.network(
                              receiptUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 42,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  currentExpense.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.formatDate(spentAt)} • ${currentExpense.category}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatVnd(currentExpense.amount),
                  style: AppTheme.monoAmount(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (currentExpense.isOcrScanned)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Chip(
                      avatar: Icon(Icons.document_scanner_outlined, size: 16),
                      label: Text('Đã quét OCR'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Hạch toán'),
          AppInsetCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Người trả'),
                  trailing: Text(
                    currentExpense.paidByName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('Nguồn tiền'),
                  trailing: Text(
                    currentExpense.paymentSource == 'group_fund'
                        ? 'Quỹ chung'
                        : 'Chi hộ / ứng trước',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('Hũ ngân sách'),
                  trailing: Text(
                    currentExpense.category,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionHeader(title: 'Phần chia (${splitEntries.length} người)'),
          AppInsetCard(
            child: Column(
              children: [
                for (var index = 0; index < splitEntries.length; index++)
                  Column(
                    children: [
                      ListTile(
                        title: Text(
                          memberNames[splitEntries[index].key] ??
                              splitEntries[index].key,
                        ),
                        trailing: Text(
                          AppFormatters.formatVnd(splitEntries[index].value),
                          style: AppTheme.monoAmount(),
                        ),
                      ),
                      if (index < splitEntries.length - 1)
                        const Divider(indent: 16),
                    ],
                  ),
              ],
            ),
          ),
          if (currentExpense.note?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            const AppSectionHeader(title: 'Ghi chú'),
            AppInsetCard(
              padding: const EdgeInsets.all(16),
              child: Text(currentExpense.note!),
            ),
          ],
        ],
      ),
    );
  }
}
