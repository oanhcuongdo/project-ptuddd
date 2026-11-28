import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kid_button.dart';
import '../../domain/entities/verbal_math_question.dart';
import '../../domain/usecases/generate_parental_gate_question.dart';
import '../../domain/usecases/validate_parental_gate_answer.dart';

class ParentalGateDialog extends StatefulWidget {
  const ParentalGateDialog({super.key});

  static final _questionGenerator = GenerateParentalGateQuestion();

  static Future<bool> authenticate(BuildContext context) async {
    final passed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const ParentalGateDialog(),
    );
    return passed == true;
  }

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late final VerbalMathQuestion _question;
  final ValidateParentalGateAnswer _answerValidator =
      const ValidateParentalGateAnswer();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  String _error = '';
  int? _selectedOption;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _question = ParentalGateDialog._questionGenerator.generate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _answerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    final parsed = _answerValidator.parseInput(value);
    setState(() {
      _error = '';
      _selectedOption = _question.options.contains(parsed) ? parsed : null;
    });
  }

  void _verifyValue(int value) {
    _controller.value = TextEditingValue(
      text: '$value',
      selection: TextSelection.collapsed(offset: '$value'.length),
    );
    setState(() {
      _selectedOption = _question.options.contains(value) ? value : null;
      _error = '';
    });
    _applyValidation(
      _answerValidator.validateValue(question: _question, value: value),
    );
  }

  void _verifyInput() {
    _applyValidation(
      _answerValidator.validateInput(
        question: _question,
        input: _controller.text,
      ),
    );
  }

  void _applyValidation(ParentalGateAnswerStatus status) {
    switch (status) {
      case ParentalGateAnswerStatus.correct:
        _close(true);
        break;
      case ParentalGateAnswerStatus.empty:
        setState(() => _error = 'Vui lòng nhập hoặc chọn đáp án.');
        break;
      case ParentalGateAnswerStatus.invalid:
        setState(() => _error = 'Vui lòng nhập đáp án bằng số hoặc chữ.');
        break;
      case ParentalGateAnswerStatus.incorrect:
        setState(() => _error = 'Kết quả chưa chính xác. Vui lòng thử lại.');
        break;
    }
  }

  void _close(bool passed) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(passed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: AppColors.cardBg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cổng bảo vệ phụ huynh',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Người lớn vui lòng trả lời câu hỏi để tiếp tục:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Text(
                    _question.questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const ValueKey('parental_gate_error'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Chọn đáp án',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _question.options.map((option) {
                    return SizedBox(
                      width: 96,
                      child: KidButton(
                        onPressed: () => _verifyValue(option),
                        label: '$option',
                        semanticLabel: 'Chọn đáp án $option',
                        backgroundColor: AppColors.buttonSecondary,
                        textColor: AppColors.textDark,
                        height: 56,
                        isSelected: _selectedOption == option,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hoặc nhập đáp án',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      _verifyInput();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _answerFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _verifyInput(),
                    onChanged: _onInputChanged,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: 8 hoặc tám',
                      filled: true,
                      fillColor: AppColors.parentSurface,
                      suffixIcon: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.textLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: KidButton(
                        onPressed: () => _close(false),
                        icon: Icons.arrow_back_rounded,
                        label: 'Quay lại',
                        semanticLabel: 'Quay lại',
                        backgroundColor: AppColors.buttonNeutral,
                        textColor: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KidButton(
                        onPressed: _verifyInput,
                        icon: Icons.lock_open_rounded,
                        label: 'Xác nhận',
                        semanticLabel: 'Xác nhận đáp án',
                        backgroundColor: AppColors.buttonPrimary,
                        textColor: AppColors.textDark,
                      ),
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
}
