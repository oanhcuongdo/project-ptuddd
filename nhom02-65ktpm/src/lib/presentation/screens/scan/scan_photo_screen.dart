import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../application/analyze_meal_photo.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/result.dart';
import '../../../core/strings/scan_strings.dart';
import '../../../data/ai/image_preparer.dart';
import '../../../domain/enums.dart';
import '../../widgets/ai_error_view.dart';
import '../review/review_meal_screen.dart';

/// Quét món ăn: chụp/chọn ảnh -> nén -> Gemini -> màn hình xác nhận.
class ScanPhotoScreen extends StatefulWidget {
  const ScanPhotoScreen({super.key, required this.source});

  final ImageSource source;

  static Future<void> open(BuildContext context, ImageSource source) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScanPhotoScreen(source: source)),
      );

  @override
  State<ScanPhotoScreen> createState() => _ScanPhotoScreenState();
}

class _ScanPhotoScreenState extends State<ScanPhotoScreen> {
  final _preparer = sl<ImagePreparer>();
  final _analyze = sl<AnalyzeMealPhoto>();

  Uint8List? _image; // chỉ giữ trong bộ nhớ, không lưu
  bool _analyzing = false;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndAnalyze());
  }

  Future<void> _pickAndAnalyze() async {
    final bytes = await _preparer.pick(widget.source);
    if (!mounted) return;
    if (bytes == null) {
      // Người dùng hủy chụp/chọn ảnh lần đầu -> quay lại.
      if (_image == null) Navigator.of(context).pop();
      return;
    }
    setState(() => _image = bytes);
    await _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final image = _image;
    if (image == null) return;
    setState(() {
      _analyzing = true;
      _failure = null;
    });
    final result = await _analyze(image);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        await ReviewMealScreen.open(
          context,
          items: value,
          inputMethod: InputMethod.photo,
          fromAi: true,
          replace: true,
        );
      case Err(:final failure):
        setState(() {
          _analyzing = false;
          _failure = failure;
        });
    }
  }

  void _manual() => ReviewMealScreen.openManual(context, replace: true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(ScanStrings.scanTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(_image!, fit: BoxFit.cover),
                ),
              )
            else
              const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 24),
            if (_analyzing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(ScanStrings.analyzing,
                  textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            ],
            if (_failure != null)
              AiErrorView(
                failure: _failure!,
                onManual: _manual,
                // Lỗi không nhận ra món -> chọn ảnh khác; lỗi khác -> thử lại ảnh cũ.
                onRetry: _failure!.type == FailureType.notRecognized
                    ? _pickAndAnalyze
                    : _runAnalysis,
                retryLabel: _failure!.type == FailureType.notRecognized
                    ? ScanStrings.pickAgain
                    : ScanStrings.analyze,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(ScanStrings.privacyNote, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
