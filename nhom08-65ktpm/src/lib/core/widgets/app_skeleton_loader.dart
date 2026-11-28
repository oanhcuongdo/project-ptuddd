import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Skeleton placeholder nhẹ khi đang tải dữ liệu từ Firestore.
class AppSkeletonLoader extends StatefulWidget {
  const AppSkeletonLoader({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 84,
  });

  final int itemCount;
  final double itemHeight;

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          AppColors.surfaceContainerHigh,
          AppColors.surfaceContainerHighest,
          _controller.value,
        )!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => Container(
            height: widget.itemHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
