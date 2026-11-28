import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_inset_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../models/trip_model.dart';
import '../../providers/trip_providers.dart';

/// Bottom Sheet hiển thị mã QR mời thành viên và danh sách thành viên hiện tại.
class TripMembersSheet extends ConsumerWidget {
  const TripMembersSheet({super.key, this.trip});

  final TripModel? trip;

  static Future<void> show(BuildContext context, {TripModel? trip}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TripMembersSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = trip ?? ref.watch(currentTripProvider).asData?.value;
    final members = ref.watch(currentTripMembersProvider).asData?.value ?? const [];

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    activeTrip?.title ?? 'Thành viên & Mã mời',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (GoRouter.maybeOf(context) != null) {
                      context.push('/trip/members');
                    }
                  },
                  child: const Text('Chi tiết'),
                ),
              ],
            ),
            if (activeTrip != null) ...[
              const SizedBox(height: 10),
              AppInsetCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariantSoft),
                      ),
                      child: QrImageView(
                        data: 'travelbuddy://join?code=${activeTrip.inviteCode}',
                        version: QrVersions.auto,
                        size: 148,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Mã mời tham gia chuyến đi',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeTrip.inviteCode,
                      style: AppTheme.monoAmount(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: activeTrip.inviteCode),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã sao chép mã mời ${activeTrip.inviteCode}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Sao chép mã mời'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'THÀNH VIÊN (${members.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            AppInsetCard(
              child: members.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa có thành viên nào.'),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < members.length; i++) ...[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: members[i].isHost
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainerHigh,
                              child: Text(
                                members[i].initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: members[i].isHost
                                      ? AppColors.onPrimaryContainer
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                            title: Text(members[i].displayName),
                            subtitle: Text(
                              'Đã góp ${AppFormatters.formatVnd(members[i].contributedAmount)}',
                            ),
                            trailing: members[i].isHost
                                ? const AppStatusBadge(
                                    label: 'Trưởng nhóm',
                                    tone: AppBadgeTone.mint,
                                  )
                                : null,
                          ),
                          if (i < members.length - 1) const Divider(indent: 68),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
