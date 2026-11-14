import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/constants/app_colors.dart';
import '../../domain/usecases/vietnamese_number_extractor.dart';

class VoiceAnswerMicButton extends StatefulWidget {
  final Function(int number, String rawSpeech) onAnswerDetected;
  final Function(String statusMessage)? onStatusChanged;

  const VoiceAnswerMicButton({
    super.key,
    required this.onAnswerDetected,
    this.onStatusChanged,
  });

  @override
  State<VoiceAnswerMicButton> createState() => _VoiceAnswerMicButtonState();
}

class _VoiceAnswerMicButtonState extends State<VoiceAnswerMicButton>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedWords = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      widget.onStatusChanged?.call('');
      return;
    }

    bool available = false;
    try {
      available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
    } catch (_) {
      available = false;
    }

    if (available) {
      setState(() {
        _isListening = true;
        _recognizedWords = '';
      });
      widget.onStatusChanged?.call('Đang lắng nghe bé nói...');

      await _speech.listen(
        localeId: 'vi_VN',
        onResult: (result) {
          setState(() {
            _recognizedWords = result.recognizedWords;
          });
          widget.onStatusChanged?.call('Bé vừa nói: "$_recognizedWords"');

          final number = VietnameseNumberExtractor.extractNumber(
            result.recognizedWords,
          );
          if (number != null) {
            _speech.stop();
            setState(() => _isListening = false);
            widget.onAnswerDetected(number, result.recognizedWords);
          }
        },
      );
    } else {
      // Nếu thiết bị không hỗ trợ Micro (ví dụ máy ảo hoặc web không cấp quyền),
      // mở hộp thoại nhập nhanh giả lập giọng nói để thuận tiện kiểm thử
      _showVoiceSimulationDialog();
    }
  }

  void _showVoiceSimulationDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('🎙️ ', style: TextStyle(fontSize: 24)),
              Text(
                'Nói đáp án (Mô phỏng)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nhập câu bé đọc (ví dụ: "dạ bằng năm", "mười lăm"):',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: bằng năm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = textController.text.trim();
                Navigator.pop(context);
                final number = VietnameseNumberExtractor.extractNumber(text);
                if (number != null) {
                  widget.onAnswerDetected(number, text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không tìm thấy số trong câu: "$text"'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final scale = _isListening ? 1.0 + (_animController.value * 0.15) : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _isListening ? AppColors.error : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? AppColors.error : AppColors.primary)
                        .withOpacity(0.4),
                    blurRadius: _isListening ? 20 : 10,
                    spreadRadius: _isListening ? 4 : 1,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        );
      },
    );
  }
}
