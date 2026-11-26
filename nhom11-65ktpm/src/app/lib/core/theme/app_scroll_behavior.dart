import 'package:flutter/material.dart';

/// Cuộn kiểu iOS cho toàn app: nảy ở mép, không dùng hiệu ứng kéo giãn của Android.
///
/// Hiệu ứng kéo giãn (StretchingOverscrollIndicator) biến đổi cả nội dung mà KHÔNG
/// đổi vị trí cuộn, nên shader kính (`LensBackdrop`) không được vẽ lại và lấy mẫu
/// nền sai chỗ: mép kính bị lệch, lòng nút trắng loá sau khi kéo quá đầu/cuối trang.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
