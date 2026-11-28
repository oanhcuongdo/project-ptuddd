import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ensures a [ProviderScope] is available for Module 2 widgets even when hosted
/// inside a shell or preview entrypoint (such as `main_ui_preview.dart`) that
/// does not wrap `runApp` in a root [ProviderScope].
class ModuleProviderScope extends StatelessWidget {
  const ModuleProviderScope({super.key, required this.child});

  final Widget child;

  static ProviderContainer? _fallbackContainer;

  static ProviderContainer get fallbackContainer =>
      _fallbackContainer ??= ProviderContainer();

  @override
  Widget build(BuildContext context) {
    try {
      ProviderScope.containerOf(context, listen: false);
      return child;
    } on StateError {
      return UncontrolledProviderScope(
        container: fallbackContainer,
        child: child,
      );
    }
  }
}
