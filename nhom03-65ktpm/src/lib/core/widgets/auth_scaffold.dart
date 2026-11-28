import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Khung màn hình form (đăng nhập/đăng ký) dùng chung — `docs/ui_ux.md` mục 7.
///
/// Nền `surface` rất nhạt với một lớp gradient `primaryContainer` mờ ở nửa
/// trên (tham chiếu `15_brand_visual.png`), nội dung rộng tối đa
/// [AppSizes.formMaxWidth] và căn trên để hai màn luôn bắt đầu cùng vị trí.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.child,
    this.showBackButton = false,
    super.key,
  });

  final Widget child;

  /// Hiện nút quay lại ở góc trên trái (dùng cho màn đăng ký).
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const <double>[0, 0.55],
            colors: <Color>[scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Thanh đầu cố định cho cả hai màn: chỉ màn đăng ký có nút lùi,
              // nhưng chiều cao giữ nguyên nên nội dung hai màn thẳng hàng.
              SizedBox(
                height: 56,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: showBackButton
                      ? Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: IconButton(
                            tooltip: 'Quay lại',
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.formMaxWidth,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
