import 'package:flutter/material.dart';

import '../../../application/analyze_food_text.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/result.dart';
import '../../../core/strings/scan_strings.dart';
import '../../../domain/enums.dart';
import '../../widgets/ai_error_view.dart';
import '../review/review_meal_screen.dart';

/// Nhập tên món bằng chữ -> AI đánh giá (chỉ văn bản) -> màn hình xác nhận.
/// AI lỗi -> người dùng tự chọn mức độ bằng chip.
class TextEntryScreen extends StatefulWidget {
  const TextEntryScreen({super.key});

  @override
  State<TextEntryScreen> createState() => _TextEntryScreenState();
}

class _TextEntryScreenState extends State<TextEntryScreen> {
  final _analyze = sl<AnalyzeFoodText>();
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _failure =
          const AppFailure(FailureType.invalidResponse, ScanStrings.textNameRequired));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await _analyze(name);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        await ReviewMealScreen.open(
          context,
          items: [value],
          inputMethod: InputMethod.manual,
          fromAi: true,
          replace: true,
        );
      case Err(:final failure):
        setState(() {
          _busy = false;
          _failure = failure;
        });
    }
  }

  void _manual() => ReviewMealScreen.openManual(
        context,
        name: _nameCtrl.text.trim(),
        replace: true,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ScanStrings.textTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            enabled: !_busy,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: ScanStrings.textLabel,
              hintText: ScanStrings.textHint,
              prefixIcon: Icon(Icons.restaurant_outlined),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: const Text(ScanStrings.analyze),
          ),
          TextButton(
            onPressed: _busy ? null : _manual,
            child: const Text(ScanStrings.chooseLevelsYourself),
          ),
          if (_failure != null) ...[
            const SizedBox(height: 24),
            AiErrorView(
              failure: _failure!,
              onManual: _manual,
              manualLabel: ScanStrings.chooseLevelsYourself,
              onRetry: _failure!.type == FailureType.invalidResponse &&
                      _nameCtrl.text.trim().isEmpty
                  ? null
                  : _submit,
            ),
          ],
        ],
      ),
    );
  }
}
