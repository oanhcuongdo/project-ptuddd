import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../chat_online/models/translation_language.dart';
import '../../../chat_online/services/translation_service.dart';
import '../helpers/chat_translate_helper.dart';
import '../styles/chat_styles.dart';

/// Hộp thoại Tách từ (Word Chips) từ câu chat:
/// Chạm vào từng từ đơn để tra nghĩa riêng và lưu thẳng vào Sổ tay (`vocab_notebook`)
/// kèm câu chat gốc làm câu ví dụ ngữ cảnh.
class MessageWordPickerDialog extends StatefulWidget {
  final String rawMessageContent;
  final Future<bool> Function({
    required String word,
    required String translatedMeaning,
    required String sourceLang,
    required String targetLang,
    required String exampleSentence,
  }) onSaveWord;
  final TranslationService? translationService;

  const MessageWordPickerDialog({
    super.key,
    required this.rawMessageContent,
    required this.onSaveWord,
    this.translationService,
  });

  static Future<void> show(
    BuildContext context, {
    required String rawMessageContent,
    required Future<bool> Function({
      required String word,
      required String translatedMeaning,
      required String sourceLang,
      required String targetLang,
      required String exampleSentence,
    }) onSaveWord,
    TranslationService? translationService,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => MessageWordPickerDialog(
        rawMessageContent: rawMessageContent,
        onSaveWord: onSaveWord,
        translationService: translationService,
      ),
    );
  }

  @override
  State<MessageWordPickerDialog> createState() =>
      _MessageWordPickerDialogState();
}

class _MessageWordPickerDialogState extends State<MessageWordPickerDialog> {
  late final TranslationService _service;
  late final String _cleanSentence;
  late final List<String> _words;
  final _meaningController = TextEditingController();

  String? _selectedWord;
  String _detectedSourceLang = 'en';
  bool _isLookingUp = false;
  bool _isSaving = false;
  String? _lookupError;
  final Set<String> _savedWords = {};

  @override
  void initState() {
    super.initState();
    _service = widget.translationService ?? TranslationService();
    _cleanSentence =
        ChatTranslateHelper.plainTextForTranslation(widget.rawMessageContent);
    _words = ChatTranslateHelper.extractWords(_cleanSentence);
    if (_words.isNotEmpty) {
      _selectWord(_words.first);
    }
  }

  @override
  void dispose() {
    _meaningController.dispose();
    super.dispose();
  }

  Future<void> _selectWord(String word) async {
    setState(() {
      _selectedWord = word;
      _isLookingUp = true;
      _lookupError = null;
      _meaningController.clear();
    });

    final fromCode = TranslationService.containsChineseCharacters(word)
        ? TranslationLanguage.zhCn.code
        : TranslationLanguage.auto.code;

    final res = await _service.translate(
      text: word,
      from: fromCode,
      to: TranslationLanguage.vi.code,
    );

    if (!mounted || _selectedWord != word) return;
    setState(() {
      _isLookingUp = false;
      if (res.hasTranslation) {
        _meaningController.text = res.translatedText;
        _detectedSourceLang = res.sourceLangEnum == TranslationLanguage.auto
            ? (TranslationService.containsChineseCharacters(word)
                ? TranslationLanguage.zhCn.code
                : TranslationLanguage.en.code)
            : res.sourceLangEnum.code;
      } else {
        _lookupError = res.errorMessage ?? 'Không tra được nghĩa từ này.';
      }
    });
  }

  Future<void> _handleSaveSelected() async {
    final word = _selectedWord;
    final meaning = _meaningController.text.trim();
    if (word == null || meaning.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    final ok = await widget.onSaveWord(
      word: word,
      translatedMeaning: meaning,
      sourceLang: _detectedSourceLang,
      targetLang: TranslationLanguage.vi.code,
      exampleSentence: _cleanSentence,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (ok) {
        _savedWords.add(word.toLowerCase());
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? ChatStyles.tealDark : AppColors.error,
        content: Text(
          ok
              ? 'Đã lưu từ "$word" vào Sổ tay từ vựng!'
              : 'Không thể lưu từ này lúc này.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadySaved = _selectedWord != null &&
        _savedWords.contains(_selectedWord!.toLowerCase());

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                      Icons.auto_awesome_mosaic_rounded,
                      size: 20,
                      color: ChatStyles.tealDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tách từ & Lưu vào Sổ tay',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Chạm vào 1 từ mới để tra nghĩa và lưu kèm câu ví dụ',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '"$_cleanSentence"',
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_words.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Không tách được từ đơn nào trong tin nhắn này.',
                    style: ChatStyles.metaText,
                  ),
                )
              else ...[
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _words.map((word) {
                    final selected = _selectedWord == word;
                    final saved = _savedWords.contains(word.toLowerCase());
                    return InkWell(
                      onTap: () => _selectWord(word),
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? ChatStyles.tealPrimary
                              : saved
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? ChatStyles.tealPrimary
                                : saved
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (saved) ...[
                              Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF047857),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              word,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : saved
                                        ? const Color(0xFF047857)
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedWord != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: ChatStyles.tealSoftBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ChatStyles.tealBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedWord!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (_isLookingUp)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ChatStyles.tealPrimary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_lookupError != null)
                          Text(
                            _lookupError!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.error,
                            ),
                          ),
                        TextField(
                          controller: _meaningController,
                          cursorColor: ChatStyles.tealPrimary,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: _isLookingUp
                                ? 'Đang tra nghĩa...'
                                : 'Nghĩa tiếng Việt (có thể sửa lại cho sát ngữ cảnh)',
                            hintStyle: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: ChatStyles.tealBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: ChatStyles.tealBorder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _isLookingUp ||
                                    _isSaving ||
                                    isAlreadySaved ||
                                    _meaningController.text.trim().isEmpty
                                ? null
                                : _handleSaveSelected,
                            style: FilledButton.styleFrom(
                              backgroundColor: isAlreadySaved
                                  ? const Color(0xFF047857)
                                  : ChatStyles.tealPrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 36),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
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
                                    isAlreadySaved
                                        ? Icons.bookmark_added_rounded
                                        : Icons.bookmark_add_outlined,
                                    size: 16,
                                  ),
                            label: Text(
                              isAlreadySaved
                                  ? 'Đã lưu vào Sổ tay'
                                  : 'Lưu từ này vào Sổ tay',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
