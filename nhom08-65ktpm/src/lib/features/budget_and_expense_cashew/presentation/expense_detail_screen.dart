import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';

/// Màn hình Chi tiết hóa đơn — chuyển từ Stitch (chi_ti_t_h_a_n).
class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ex = MockTripData.expenses.first;
    final perPerson = (ex.amount / MockTripData.members.length).round();

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Đóng', style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        leadingWidth: 68,
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          TextButton(
            onPressed: () => context.push('/trip/budget/add'),
            child: const Text('Sửa', style: TextStyle(color: AppColors.onPrimaryContainer)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ảnh hóa đơn
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 42, color: AppColors.primary),
                      SizedBox(height: 6),
                      Text(
                        'Ảnh hóa đơn đã chụp OCR',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(ex.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(ex.dateTime, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(
                  MockTripData.formatVnd(ex.amount),
                  style: AppTheme.monoAmount(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const AppSectionHeader(title: 'Người ứng tiền'),
          AppInsetCard(
            child: ListTile(
              title: const Text('Người thanh toán'),
              trailing: Text(
                ex.payerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),

          AppSectionHeader(title: 'Chi tiết chia tiền (${MockTripData.members.length} người)'),
          AppInsetCard(
            child: Column(
              children: List.generate(MockTripData.members.length, (i) {
                final m = MockTripData.members[i];
                final (label, tone) = i == 0
                    ? ('Chủ chi', AppBadgeTone.primary)
                    : i == 2
                        ? ('Đã trả', AppBadgeTone.mint)
                        : ('Chưa trả', AppBadgeTone.amber);
                return Column(
                  children: [
                    ListTile(
                      title: Text(m.name),
                      subtitle: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AppStatusBadge(label: label, tone: tone),
                        ),
                      ),
                      trailing: Text(MockTripData.formatVnd(perPerson), style: AppTheme.monoAmount()),
                    ),
                    if (i < MockTripData.members.length - 1) const Divider(indent: 16),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 46,
            child: FilledButton.tonal(
              onPressed: () => context.pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorContainer,
                foregroundColor: AppColors.onErrorContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Xóa hóa đơn', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
