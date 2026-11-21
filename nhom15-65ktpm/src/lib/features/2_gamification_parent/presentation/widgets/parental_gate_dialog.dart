import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../4_ai_voice_tutor/domain/usecases/vietnamese_number_extractor.dart';

class VerbalMathQuestion {
  final String questionText;
  final int answer;
  final List<int> options;

  const VerbalMathQuestion({
    required this.questionText,
    required this.answer,
    required this.options,
  });

  static const List<String> _words = [
    'Không',
    'Một',
    'Hai',
    'Ba',
    'Bốn',
    'Năm',
    'Sáu',
    'Bảy',
    'Tám',
    'Chín',
    'Mười',
    'Mười một',
    'Mười hai',
    'Mười ba',
    'Mười bốn',
    'Mười lăm',
    'Mười sáu',
  ];

  static VerbalMathQuestion generate() {
    final random = Random();
    final isAdd = random.nextBool();

    int a, b, ans;
    String q;

    if (isAdd) {
      a = random.nextInt(7) + 3; // 3 - 9
      b = random.nextInt(6) + 2; // 2 - 7
      ans = a + b;
      q = '${_words[a]} cộng ${_words[b].toLowerCase()} bằng mấy?';
    } else {
      a = random.nextInt(7) + 8; // 8 - 14
      b = random.nextInt(5) + 2; // 2 - 6
      ans = a - b;
      q = '${_words[a]} trừ ${_words[b].toLowerCase()} bằng mấy?';
    }

    final optsSet = <int>{ans};
    while (optsSet.length < 4) {
      final delta = random.nextInt(5) - 2;
      final fake = ans + (delta == 0 ? 1 : delta);
      if (fake >= 0) optsSet.add(fake);
    }
    final options = optsSet.toList()..shuffle();

    return VerbalMathQuestion(
      questionText: q,
      answer: ans,
      options: options,
    );
  }
}

class ParentalGateDialog extends StatefulWidget {
  final VoidCallback onPass;

  const ParentalGateDialog({super.key, required this.onPass});

  static void show(BuildContext context, {required VoidCallback onPass}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ParentalGateDialog(onPass: onPass),
    );
  }

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late VerbalMathQuestion _question;
  final TextEditingController _controller = TextEditingController();
  String _error = '';

  @override
  void initState() {
    super.initState();
    _refreshQuestion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refreshQuestion() {
    setState(() {
      _question = VerbalMathQuestion.generate();
      _controller.clear();
      _error = '';
    });
  }

  void _verifyValue(int value) {
    if (value == _question.answer) {
      Navigator.pop(context);
      widget.onPass();
    } else {
      setState(() {
        _error = 'Kết quả chưa chính xác! Hãy giải lại câu hỏi mới dưới đây:';
        _question = VerbalMathQuestion.generate();
        _controller.clear();
      });
    }
  }

  void _verifyInput() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Cho phép nhập số (ví dụ: "7") hoặc chữ tiếng Việt (ví dụ: "bảy", "mười một")
    int? parsed = int.tryParse(text);
    parsed ??= VietnameseNumberExtractor.extractNumber(text);

    if (parsed != null) {
      _verifyValue(parsed);
    } else {
      setState(() {
        _error = 'Vui lòng nhập số hoặc chữ hợp lệ.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cổng Bảo Vệ Phụ Huynh',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Để đảm bảo an toàn cho trẻ, bố mẹ vui lòng trả lời câu hỏi toán học dưới đây:',
              style: TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Text(
                '📝 "${_question.questionText}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _error,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Chọn nhanh đáp án:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _question.options.map((opt) {
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _verifyValue(opt),
                  child: Text(
                    '$opt',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hoặc nhập số / chữ trực tiếp:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              onSubmitted: (_) => _verifyInput(),
              decoration: InputDecoration(
                hintText: 'Ví dụ: 7 hoặc bảy',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                  onPressed: _verifyInput,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: AppColors.textLight)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _verifyInput,
          child: const Text('Mở Khóa'),
        ),
      ],
    );
  }
}
