import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Ô tìm kiếm dùng chung: bo tròn, icon kính lúp, nút xoá khi có chữ.
///
/// Bố cục tham chiếu thanh tìm kiếm cố định đầu màn của Google Keep.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    required this.hintText,
    this.onChanged,
    this.autofocus = false,
    this.dense = false,
    super.key,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool dense;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (BuildContext context, TextEditingValue value, _) {
        return TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          onChanged: (String text) {
            widget.onChanged?.call(text);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            isDense: widget.dense,
            constraints: widget.dense
                ? const BoxConstraints(minHeight: NotesLayout.controlHeight)
                : null,
            prefixIconConstraints: widget.dense
                ? const BoxConstraints.tightFor(
                    width: NotesLayout.controlHeight,
                    height: NotesLayout.controlHeight,
                  )
                : null,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    onPressed: _clear,
                    tooltip: 'Xoá tìm kiếm',
                    icon: const Icon(Icons.close_rounded),
                    constraints: widget.dense
                        ? const BoxConstraints.tightFor(
                            width: NotesLayout.controlHeight,
                            height: NotesLayout.controlHeight,
                          )
                        : null,
                  ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: widget.dense ? AppSpacing.sm : AppSpacing.md,
            ),
            fillColor: scheme.surfaceContainerHigh,
          ),
        );
      },
    );
  }
}
