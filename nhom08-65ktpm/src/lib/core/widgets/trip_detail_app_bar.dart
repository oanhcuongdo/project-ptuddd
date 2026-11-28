import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// AppBar chuẩn cho 4 tab chi tiết chuyến đi: nút back về Trang chủ + tiêu đề + nút Thành viên/QR.
class TripDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TripDetailAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onMembersPressed,
    this.extraActions = const [],
    this.showMembersButton = true,
  });

  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMembersPressed;
  final List<Widget> extraActions;
  final bool showMembersButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    return AppBar(
      leading: IconButton(
        tooltip: 'Danh sách chuyến đi',
        icon: const Icon(Icons.arrow_back, color: AppColors.onPrimaryContainer),
        onPressed: onBackPressed ??
            () {
              if (router != null) {
                context.go('/trips');
              } else {
                Navigator.of(context).maybePop();
              }
            },
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        ...extraActions,
        if (showMembersButton)
          IconButton(
            key: const Key('trip_detail_members_button'),
            tooltip: 'Thành viên & Mã QR',
            icon: const Icon(
              Icons.qr_code_2_outlined,
              color: AppColors.primary,
            ),
            onPressed: onMembersPressed ??
                (router != null ? () => context.push('/trip/members') : null),
          ),
      ],
    );
  }
}
