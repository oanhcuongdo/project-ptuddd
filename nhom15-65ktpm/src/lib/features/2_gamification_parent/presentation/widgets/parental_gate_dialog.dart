import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ParentalGateDialog extends StatefulWidget {
  final VoidCallback onPass;

  const ParentalGateDialog({super.key, required this.onPass});

  static void show(BuildContext context, {required VoidCallback onPass}) {
    showDialog(
      context: context,
      builder: (context) => ParentalGateDialog(onPass: onPass),
    );
  }

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late int _num1;
  late int _num2;
  late int _correctAnswer;
  final TextEditingController _controller = TextEditingController();
  String _error = '';

  @override
  void initState() {
    super.initState();
    final random = Random();
    _num1 = random.nextInt(35) + 25; // 25 - 59
    _num2 = random.nextInt(25) + 15; // 15 - 39
    _correctAnswer = _num1 + _num2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    final input = int.tryParse(_controller.text.trim());
    if (input == _correctAnswer) {
      Navigator.pop(context);
      widget.onPass();
    } else {
      setState(() {
        _error = 'Kết quả chưa đúng, vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.lock, color: AppColors.primary),
          SizedBox(width: 8),
          Text(
            'Khu Vực Phụ Huynh',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Để mở khu vực báo cáo & cài đặt, bố mẹ vui lòng giải phép cộng sau:',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          Text(
            '$_num1 + $_num2 = ?',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Nhập đáp án',
              errorText: _error.isEmpty ? null : _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (_) => _verify(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Mở Khóa'),
        ),
      ],
    );
  }
}
