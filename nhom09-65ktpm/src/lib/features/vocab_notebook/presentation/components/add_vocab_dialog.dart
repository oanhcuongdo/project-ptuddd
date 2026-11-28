import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../chat_online/models/translation_language.dart';
import '../../../chat_online/services/translation_service.dart';
import '../../data/models/vocab_entry_model.dart';
import '../styles/vocab_styles.dart';

/// Dữ liệu trả về khi người dùng xác nhận Thêm hoặc Chỉnh sửa từ vựng trong [AddVocabDialog].
class VocabFormResult {
  final String word;
  final String translatedMeaning;
  final String sourceLang;
  final String targetLang;
  final String exampleSentence;

  const VocabFormResult({
    required this.word,
    required this.translatedMeaning,
    required this.sourceLang,
    required this.targetLang,
    required this.exampleSentence,
  });
}

/// Hộp thoại Thêm mới hoặc Chỉnh sửa từ vựng thủ công (kèm nút Dịch gợi ý tự động).
class AddVocabDialog extends StatefulWidget {
  final VocabEntryModel? existing;
  final TranslationService? translationService;

  const AddVocabDialog({
    super.key,
    this.existing,
    this.translationService,
  });

  static Future<VocabFormResult?> show(
    BuildContext context, {
    VocabEntryModel? existing,
    TranslationService? translationService,
  }) {
    return showDialog<VocabFormResult>(
      context: context,
      builder: (_) => AddVocabDialog(
        existing: existing,
        translationService: translationService,
      ),
    );
  }

  @override
  State<AddVocabDialog> createState() => _AddVocabDialogState();
}

class _AddVocabDialogState extends State<AddVocabDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _wordController;
  late final TextEditingController _meaningController;
  late final TextEditingController _exampleController;
  late final TranslationService _service;

  late TranslationLanguage _sourceLang;
  late TranslationLanguage _targetLang;
  bool _isTranslatingHint = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _service = widget.translationService ?? TranslationService();
    final e = widget.existing;
    _wordController = TextEditingController(text: e?.word ?? '');
    _meaningController =
        TextEditingController(text: e?.translatedMeaning ?? '');
    _exampleController = TextEditingController(text: e?.exampleSentence ?? '');

    final src = TranslationLanguage.fromCode(e?.sourceLang ?? 'en');
    _sourceLang = src == TranslationLanguage.auto
        ? TranslationLanguage.en
        : src;

    final tgt = TranslationLanguage.fromCode(e?.targetLang ?? 'vi');
    _targetLang = tgt == TranslationLanguage.auto
        ? TranslationLanguage.vi
        : tgt;
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<void> _autoFillMeaning() async {
    final word = _wordController.text.trim();
    if (word.isEmpty || _isTranslatingHint) return;

    setState(() => _isTranslatingHint = true);
    final res = await _service.translateWithLanguages(
      text: word,
      from: _sourceLang,
      to: _targetLang,
    );

    if (!mounted) return;
    setState(() => _isTranslatingHint = false);

    if (res.hasTranslation) {
      _meaningController.text = res.translatedText;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Không thể gợi ý bản dịch lúc này.'),
        ),
      );
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      VocabFormResult(
        word: _wordController.text.trim(),
        translatedMeaning: _meaningController.text.trim(),
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
        exampleSentence: _exampleController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      child: Icon(
                        _isEditing
                            ? Icons.edit_note_rounded
                            : Icons.bookmark_add_rounded,
                        color: VocabStyles.tealDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Chỉnh sửa từ vựng' : 'Thêm từ vựng mới',
                        style: VocabStyles.sectionTitle,
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
                    Expanded(
                      child: _buildLangField(
                        label: 'Ngôn ngữ gốc',
                        value: _sourceLang,
                        onChanged: (val) {
                          if (val != null) setState(() => _sourceLang = val);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildLangField(
                        label: 'Ngôn ngữ dịch',
                        value: _targetLang,
                        onChanged: (val) {
                          if (val != null) setState(() => _targetLang = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Từ vựng / Cụm từ *',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _wordController,
                  cursorColor: VocabStyles.tealPrimary,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: VocabStyles.inputDecoration(
                    hintText: 'Ví dụ: fluency, 坚持...',
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Vui lòng nhập từ vựng'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Text(
                      'Nghĩa dịch *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isTranslatingHint ? null : _autoFillMeaning,
                      style: TextButton.styleFrom(
                        foregroundColor: VocabStyles.tealDark,
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: _isTranslatingHint
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 15),
                      label: const Text(
                        'Dịch gợi ý',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _meaningController,
                  cursorColor: VocabStyles.tealPrimary,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: VocabStyles.inputDecoration(
                    hintText: 'Ví dụ: sự trôi chảy, kiên trì...',
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Vui lòng nhập nghĩa dịch'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Câu ví dụ ngữ cảnh (tùy chọn)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _exampleController,
                  cursorColor: VocabStyles.tealPrimary,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  decoration: VocabStyles.inputDecoration(
                    hintText: 'Ví dụ: Daily practice improves speaking fluency.',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: VocabStyles.tealPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save_rounded, size: 17),
                      label: Text(_isEditing ? 'Lưu thay đổi' : 'Lưu vào Sổ tay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangField({
    required String label,
    required TranslationLanguage value,
    required ValueChanged<TranslationLanguage?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TranslationLanguage>(
              value: value,
              isExpanded: true,
              isDense: true,
              dropdownColor: Colors.white,
              iconEnabledColor: VocabStyles.tealDark,
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
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
