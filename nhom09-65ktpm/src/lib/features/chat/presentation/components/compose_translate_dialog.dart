import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../chat_online/models/translation_language.dart';
import '../../../chat_online/services/translation_service.dart';
import '../styles/chat_styles.dart';

enum ComposeTranslateAction { replaceInput, sendBilingual }

class ComposeTranslateResult {
  final ComposeTranslateAction action;
  final String originalText;
  final String translatedText;

  const ComposeTranslateResult({
    required this.action,
    required this.originalText,
    required this.translatedText,
  });
}

/// Hộp thoại "Dịch hộ khi bí từ" từ thanh nhập chat:
/// Nhập câu tiếng Việt -> xem trước bản dịch (Anh / Trung) -> chọn "Thay vào ô chat" hoặc "Gửi song ngữ".
class ComposeTranslateDialog extends StatefulWidget {
  final String initialText;
  final TranslationLanguage defaultTargetLang;
  final TranslationService? translationService;

  const ComposeTranslateDialog({
    super.key,
    required this.initialText,
    this.defaultTargetLang = TranslationLanguage.en,
    this.translationService,
  });

  static Future<ComposeTranslateResult?> show(
    BuildContext context, {
    required String initialText,
    TranslationLanguage defaultTargetLang = TranslationLanguage.en,
    TranslationService? translationService,
  }) {
    return showDialog<ComposeTranslateResult>(
      context: context,
      builder: (_) => ComposeTranslateDialog(
        initialText: initialText,
        defaultTargetLang: defaultTargetLang,
        translationService: translationService,
      ),
    );
  }

  @override
  State<ComposeTranslateDialog> createState() => _ComposeTranslateDialogState();
}

class _ComposeTranslateDialogState extends State<ComposeTranslateDialog> {
  late final TextEditingController _sourceController;
  late final TextEditingController _translatedController;
  late final TranslationService _service;
  late TranslationLanguage _targetLang;
  bool _isTranslating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.translationService ?? TranslationService();
    _sourceController = TextEditingController(text: widget.initialText.trim());
    _translatedController = TextEditingController();
    _targetLang = widget.defaultTargetLang == TranslationLanguage.auto
        ? TranslationLanguage.en
        : widget.defaultTargetLang;

    if (_sourceController.text.isNotEmpty) {
      _runTranslate();
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _translatedController.dispose();
    super.dispose();
  }

  Future<void> _runTranslate() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty || _isTranslating) return;

    setState(() {
      _isTranslating = true;
      _error = null;
    });

    final res = await _service.translateWithLanguages(
      text: text,
      from: TranslationLanguage.auto,
      to: _targetLang,
    );

    if (!mounted) return;
    setState(() {
      _isTranslating = false;
      if (res.hasTranslation) {
        _translatedController.text = res.translatedText;
      } else {
        _error = res.errorMessage ?? 'Không thể dịch nội dung lúc này.';
      }
    });
  }

  void _finish(ComposeTranslateAction action) {
    final original = _sourceController.text.trim();
    final translated = _translatedController.text.trim();
    if (translated.isEmpty) return;
    Navigator.of(context).pop(
      ComposeTranslateResult(
        action: action,
        originalText: original,
        translatedText: translated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_isTranslating && _translatedController.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ChatStyles.tealSoftBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ChatStyles.tealBorder),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: ChatStyles.tealDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dịch hộ & Gửi song ngữ',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Gõ tiếng Việt, xem trước bản dịch rồi gửi ngay',
                          style: ChatStyles.metaText,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Text(
                    'Dịch sang:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TranslationLanguage>(
                        value: _targetLang,
                        isDense: true,
                        dropdownColor: Colors.white,
                        iconEnabledColor: ChatStyles.tealDark,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        items: TranslationLanguage.selectableLanguages
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text(l.labelWithFlag),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _targetLang = val);
                          _runTranslate();
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isTranslating ? null : _runTranslate,
                    style: TextButton.styleFrom(
                      foregroundColor: ChatStyles.tealDark,
                    ),
                    icon: _isTranslating
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Dịch lại'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Câu bạn muốn nói',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _sourceController,
                maxLines: 2,
                cursorColor: ChatStyles.tealPrimary,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Hôm nay bạn luyện nói thế nào rồi?',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Bản dịch xem trước (có thể chỉnh sửa)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ChatStyles.tealDark,
                ),
              ),
              const SizedBox(height: 6),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.error),
                  ),
                ),
              TextField(
                controller: _translatedController,
                maxLines: 3,
                minLines: 2,
                cursorColor: ChatStyles.tealPrimary,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _isTranslating
                      ? 'Đang dịch...'
                      : 'Bản dịch sẽ hiển thị tại đây...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: ChatStyles.tealSoftBg,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ChatStyles.tealBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ChatStyles.tealBorder),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: canSubmit
                        ? () => _finish(ComposeTranslateAction.replaceInput)
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ChatStyles.tealDark,
                      side: const BorderSide(color: ChatStyles.tealBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Thay vào ô chat',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: canSubmit
                        ? () => _finish(ComposeTranslateAction.sendBilingual)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ChatStyles.tealPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text(
                      'Gửi song ngữ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
