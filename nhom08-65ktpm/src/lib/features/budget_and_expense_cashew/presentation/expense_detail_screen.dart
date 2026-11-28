import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../auth_and_group/providers/trip_providers.dart';
import '../models/trip_expense.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, this.expense});

  final TripExpense? expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mock = MockTripData.expenses.first;
    final members =
        ref.watch(currentTripMembersProvider).asData?.value ?? const [];
    final memberNames = {
      for (final member in members) member.userId: member.displayName,
    };
    final title = expense?.title ?? mock.title;
    final amount = expense?.amount ?? mock.amount;
    final category = expense?.category ?? mock.category;
    final paidBy = expense?.paidByName ?? mock.payerName;
    final splitDetails =
        expense?.splitDetails ??
        {
          for (final member in MockTripData.members)
            member.id: (mock.amount / MockTripData.members.length).round(),
        };
    final splitEntries = splitDetails.entries.toList();
    final receiptUrl = expense?.receiptImageUrl;
    final spentAt = expense?.spentAt;

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
                ClipRRect(
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
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spentAt == null
                      ? 'Hạng mục: $category'
                      : '${spentAt.day.toString().padLeft(2, '0')}/'
                            '${spentAt.month.toString().padLeft(2, '0')}/'
                            '${spentAt.year} • $category',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  MockTripData.formatVnd(amount),
                  style: AppTheme.monoAmount(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (expense?.isOcrScanned == true)
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
                    paidBy,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('Nguồn tiền'),
                  trailing: Text(
                    expense?.paymentSource == 'group_fund'
                        ? 'Quỹ chung'
                        : 'Chi hộ / ứng trước',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('Hũ ngân sách'),
                  trailing: Text(
                    category,
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
                          MockTripData.formatVnd(splitEntries[index].value),
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
          if (expense?.note?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            const AppSectionHeader(title: 'Ghi chú'),
            AppInsetCard(
              padding: const EdgeInsets.all(16),
              child: Text(expense!.note!),
            ),
          ],
        ],
      ),
    );
  }
}
