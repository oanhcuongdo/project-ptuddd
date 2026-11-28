import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../providers/trip_providers.dart';

/// Màn hình Thành viên & Hồ sơ — hiển thị danh sách thành viên realtime từ Firestore.
class MembersProfileScreen extends ConsumerWidget {
  const MembersProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(currentTripProvider);
    final membersAsync = ref.watch(currentTripMembersProvider);
    final trip = tripAsync.asData?.value;
    final members = membersAsync.asData?.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: AppColors.onPrimaryContainer,
            size: 28,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Thành viên (${members.length})'),
        actions: [
          TextButton(
            onPressed: () async {
              final code = trip?.inviteCode;
              if (code != null && code.isNotEmpty) {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã sao chép mã mời nhóm: $code')),
                );
              } else {
                context.push('/trips/create');
              }
            },
            child: const Text(
              'Mời',
              style: TextStyle(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi tải thành viên: $err')),
        data: (memberList) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (trip != null) ...[
                AppInsetCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mã mời nhóm: ${trip.inviteCode}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppStatusBadge(
                        label: AppFormatters.formatVnd(trip.perMemberTarget),
                        tone: AppBadgeTone.amber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const AppSectionHeader(title: 'Danh sách thành viên'),
              if (memberList.isEmpty)
                const AppInsetCard(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có thành viên nào trong chuyến đi.'),
                )
              else
                AppInsetCard(
                  child: Column(
                    children: List.generate(memberList.length, (index) {
                      final m = memberList[index];
                      final roleLabel =
                          m.isHost ? 'Trưởng nhóm' : 'Thành viên';
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: m.isHost
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainerHigh,
                              child: Text(
                                m.initials,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: m.isHost
                                      ? AppColors.onPrimaryContainer
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                            title: Text(
                              m.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '$roleLabel • Chuỗi ${m.currentStreak} kỳ 🔥 • Đã góp ${AppFormatters.formatVnd(m.contributedAmount)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            trailing: m.isHost
                                ? const AppStatusBadge(
                                    label: 'Host',
                                    tone: AppBadgeTone.mint,
                                  )
                                : null,
                          ),
                          if (index < memberList.length - 1)
                            const Divider(indent: 72),
                        ],
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 24),
              const AppSectionHeader(title: 'Liên kết Quỹ & Quyết toán'),
              AppInsetCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: const Text('Quỹ nhóm MoMo'),
                      subtitle: Text(trip?.title ?? 'Quỹ chung chuyến đi'),
                      trailing: const AppStatusBadge(
                        label: 'Xem quỹ',
                        tone: AppBadgeTone.momo,
                      ),
                      onTap: () => context.go('/trip/momo'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
