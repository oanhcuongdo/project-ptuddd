import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../chat_online/models/translation_language.dart';
import '../../../chat_online/models/translation_result.dart';
import '../../../chat_online/services/translation_service.dart';
import '../styles/vocab_styles.dart';

/// Hộp tra cứu & dịch nhanh 3 ngôn ngữ (Trung ⇄ Việt ⇄ Anh) ngay trong Sổ tay Từ vựng.
/// Cho phép đảo chiều ngôn ngữ 1 chạm, sao chép kết quả và lưu thẳng thành thẻ từ vựng.
class VocabTranslatorBox extends StatefulWidget {
  final Future<bool> Function({
    required String word,
    required String translatedMeaning,
    required String sourceLang,
    required String targetLang,
  }) onSaveToNotebook;

  final TranslationService? translationService;

  const VocabTranslatorBox({
    super.key,
    required this.onSaveToNotebook,
    this.translationService,
  });

  @override
  State<VocabTranslatorBox> createState() => _VocabTranslatorBoxState();
}

class _VocabTranslatorBoxState extends State<VocabTranslatorBox> {
  final _controller = TextEditingController();
  late final TranslationService _service;

  TranslationLanguage _sourceLang = TranslationLanguage.auto;
  TranslationLanguage _targetLang = TranslationLanguage.vi;
  TranslationResult? _result;
  bool _isTranslating = false;
  bool _isSaving = false;
  bool _savedCurrent = false;

  @override
  void initState() {
    super.initState();
    _service = widget.translationService ?? TranslationService();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _swapLanguages() {
    setState(() {
      final resolvedSource = _sourceLang == TranslationLanguage.auto
          ? (_result != null &&
                  _result!.sourceLangEnum != TranslationLanguage.auto
              ? _result!.sourceLangEnum
              : TranslationLanguage.en)
          : _sourceLang;

      final previousTarget = _targetLang;
      _sourceLang = previousTarget;
      _targetLang = resolvedSource == previousTarget
          ? TranslationLanguage.defaultTargetFor(previousTarget)
          : resolvedSource;

      if (_result != null && _result!.hasTranslation) {
        _controller.text = _result!.translatedText;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      }
      _result = null;
      _savedCurrent = false;
    });
  }

  Future<void> _handleTranslate() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTranslating) return;

    setState(() {
      _isTranslating = true;
      _savedCurrent = false;
    });

    final res = await _service.translateWithLanguages(
      text: text,
      from: _sourceLang,
      to: _targetLang,
    );

    if (!mounted) return;
    setState(() {
      _isTranslating = false;
      _result = res;
    });
  }

  Future<void> _handleCopy() async {
    final translated = _result?.translatedText.trim() ?? '';
    if (translated.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: translated));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép bản dịch vào bộ nhớ tạm.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSave() async {
    final res = _result;
    if (res == null || !res.hasTranslation || _isSaving || _savedCurrent) {
      return;
    }

    setState(() => _isSaving = true);
    final resolvedSource = res.sourceLangEnum == TranslationLanguage.auto
        ? TranslationLanguage.en.code
        : res.sourceLangEnum.code;

    final ok = await widget.onSaveToNotebook(
      word: res.originalText,
      translatedMeaning: res.translatedText,
      sourceLang: resolvedSource,
      targetLang: res.targetLangEnum.code,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (ok) _savedCurrent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: VocabStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VocabStyles.tealSoftBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VocabStyles.tealBorder),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  size: 19,
                  color: VocabStyles.tealDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tra cứu & Dịch nhanh 3 thứ tiếng',
                      style: VocabStyles.sectionTitle,
                    ),
                    Text(
                      'Trung ⇄ Việt ⇄ Anh — Lưu 1 chạm vào Sổ tay cá nhân',
                      style: VocabStyles.metaText,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLanguageSelectorRow(),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 2,
                  minLines: 1,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _handleTranslate(),
                  onChanged: (_) {
                    if (_savedCurrent) {
                      setState(() => _savedCurrent = false);
                    }
                  },
                  decoration: VocabStyles.inputDecoration(
                    hintText: 'Nhập từ mới hoặc câu tiếng Anh / Trung / Việt...',
                    prefixIcon: Icons.search_rounded,
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _result = null;
                                _savedCurrent = false;
                              });
                            },
                            tooltip: 'Xóa nội dung',
                            icon: const Icon(Icons.close_rounded, size: 18),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _isTranslating ? null : _handleTranslate,
                style: FilledButton.styleFrom(
                  backgroundColor: VocabStyles.tealPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                icon: _isTranslating
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bolt_rounded, size: 18),
                label: Text(_isTranslating ? 'Đang dịch' : 'Dịch ngay'),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildResultCard(_result!),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorRow() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LanguageDropdown(
          value: _sourceLang,
          options: TranslationLanguage.sourceOptions,
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _sourceLang = val;
              if (_sourceLang == _targetLang) {
                _targetLang = TranslationLanguage.defaultTargetFor(_sourceLang);
              }
              _result = null;
              _savedCurrent = false;
            });
          },
        ),
        IconButton.filledTonal(
          onPressed: _swapLanguages,
          tooltip: 'Đảo chiều ngôn ngữ',
          style: IconButton.styleFrom(
            backgroundColor: VocabStyles.tealSoftBg,
            foregroundColor: VocabStyles.tealDark,
            fixedSize: const Size(36, 36),
          ),
          icon: const Icon(Icons.swap_horiz_rounded, size: 19),
        ),
        _LanguageDropdown(
          value: _targetLang,
          options: TranslationLanguage.selectableLanguages,
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _targetLang = val;
              _result = null;
              _savedCurrent = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildResultCard(TranslationResult res) {
    if (!res.isSuccess) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                res.errorMessage ?? 'Không thể dịch nội dung này.',
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: VocabStyles.tealSoftBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: VocabStyles.tealBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: VocabStyles.tealPillBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  res.languagePairLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: VocabStyles.tealDark,
                  ),
                ),
              ),
              if (res.fromCache) ...[
                const SizedBox(width: 6),
                const Text(
                  '• Từ Cache 0ms',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: VocabStyles.tealPrimary,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: _handleCopy,
                tooltip: 'Sao chép bản dịch',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 17,
                  color: VocabStyles.tealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            res.translatedText,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _savedCurrent || _isSaving ? null : _handleSave,
              style: FilledButton.styleFrom(
                backgroundColor: _savedCurrent
                    ? VocabStyles.masteredText
                    : VocabStyles.tealDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _savedCurrent
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                      size: 17,
                    ),
              label: Text(
                _savedCurrent ? 'Đã lưu vào Sổ tay' : 'Lưu vào Sổ tay',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final TranslationLanguage value;
  final List<TranslationLanguage> options;
  final ValueChanged<TranslationLanguage?> onChanged;

  const _LanguageDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TranslationLanguage>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: options
              .map(
                (lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(lang.labelWithFlag),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
