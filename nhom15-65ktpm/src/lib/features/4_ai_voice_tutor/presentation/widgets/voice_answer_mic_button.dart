import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/constants/app_colors.dart';
import '../../domain/usecases/vietnamese_number_extractor.dart';

enum VoiceMicState {
  idle,
  listening,
  processing,
  hintShown,
  error,
}

class VoiceAnswerMicButton extends StatefulWidget {
  final Function(int number, String rawSpeech) onAnswerDetected;
  final Function(String speechOrReason)? onHintRequested;
  final Function(String statusMessage)? onStatusChanged;
  final Function(String errorMessage)? onError;

  const VoiceAnswerMicButton({
    super.key,
    required this.onAnswerDetected,
    this.onHintRequested,
    this.onStatusChanged,
    this.onError,
  });

  @override
  State<VoiceAnswerMicButton> createState() => _VoiceAnswerMicButtonState();
}

class _VoiceAnswerMicButtonState extends State<VoiceAnswerMicButton>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  VoiceMicState _state = VoiceMicState.idle;
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

  void _setState(VoiceMicState newState) {
    if (mounted) {
      setState(() => _state = newState);
    }
  }

  Future<void> _toggleListening() async {
    if (_state == VoiceMicState.listening) {
      await _speech.stop();
      _setState(VoiceMicState.idle);
      widget.onStatusChanged?.call('Đã dừng nghe.');
      return;
    }

    bool available = false;
    try {
      available = await _speech.initialize(
        onError: (val) {
          _setState(VoiceMicState.error);
          widget.onStatusChanged?.call('Lỗi nhận diện giọng nói: ${val.errorMsg}');
          widget.onError?.call(val.errorMsg);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _state == VoiceMicState.error) {
              _setState(VoiceMicState.idle);
            }
          });
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (_state == VoiceMicState.listening) {
              _setState(VoiceMicState.idle);
            }
          }
        },
      );
    } catch (_) {
      available = false;
    }

    if (available) {
      _setState(VoiceMicState.listening);
      _recognizedWords = '';
      widget.onStatusChanged?.call('Đang lắng nghe bé nói... Hãy đọc to đáp án nhé!');

      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(localeId: 'vi_VN'),
        onResult: (result) {
          _recognizedWords = result.recognizedWords;
          widget.onStatusChanged?.call('Bé vừa nói: "$_recognizedWords"');

          final extraction = VietnameseNumberExtractor.extract(_recognizedWords);

          // 1. Nếu bé nói "con không biết", "chịu", "khó quá" -> Kích hoạt gợi ý (hint)
          if (extraction.isUnknown) {
            _speech.stop();
            _setState(VoiceMicState.hintShown);
            widget.onStatusChanged?.call('Đừng lo bé nhé! Xem gợi ý thị phạm nào! 💡');
            widget.onHintRequested?.call(_recognizedWords);
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _state == VoiceMicState.hintShown) {
                _setState(VoiceMicState.idle);
              }
            });
            return;
          }

          // 2. Nếu trích xuất được số đáp án
          if (extraction.isNumber && extraction.value != null) {
            _speech.stop();
            _setState(VoiceMicState.processing);
            widget.onStatusChanged?.call('Đã nhận diện: ${extraction.value}');

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _setState(VoiceMicState.idle);
                widget.onAnswerDetected(extraction.value!, _recognizedWords);
              }
            });
          }
        },
      );
    } else {
      // Fallback khi trình duyệt / máy ảo không có quyền hoặc không hỗ trợ Web Speech API
      _showVoiceSimulationDialog();
    }
  }

  void _showVoiceSimulationDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Text('🎙️ ', style: TextStyle(fontSize: 24)),
              Expanded(
                child: Text(
                  'Nói đáp án (Mô phỏng AI)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập câu phát ngôn tự nhiên của bé:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: "dạ thưa cô bằng 15 ạ" hoặc "con không biết"',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gợi ý câu mẫu nhanh:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _quickPhraseChip(textController, 'dạ bằng năm'),
                  _quickPhraseChip(textController, 'hai mươi mốt'),
                  _quickPhraseChip(textController, 'mười lăm ạ'),
                  _quickPhraseChip(textController, 'con không biết'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final text = textController.text.trim();
                Navigator.pop(context);
                final extraction = VietnameseNumberExtractor.extract(text);

                if (extraction.isUnknown) {
                  _setState(VoiceMicState.hintShown);
                  widget.onHintRequested?.call(text);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) _setState(VoiceMicState.idle);
                  });
                } else if (extraction.isNumber && extraction.value != null) {
                  widget.onAnswerDetected(extraction.value!, text);
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

  Widget _quickPhraseChip(TextEditingController controller, String phrase) {
    return ActionChip(
      label: Text(phrase, style: const TextStyle(fontSize: 12)),
      onPressed: () => controller.text = phrase,
      backgroundColor: AppColors.cardBg,
    );
  }

  Color _getButtonColor() {
    switch (_state) {
      case VoiceMicState.listening:
        return AppColors.error;
      case VoiceMicState.processing:
        return AppColors.secondary;
      case VoiceMicState.hintShown:
        return AppColors.accentOrange;
      case VoiceMicState.error:
        return Colors.red.shade700;
      case VoiceMicState.idle:
        return AppColors.primary;
    }
  }

  IconData _getIcon() {
    switch (_state) {
      case VoiceMicState.listening:
        return Icons.mic;
      case VoiceMicState.processing:
        return Icons.hourglass_top;
      case VoiceMicState.hintShown:
        return Icons.lightbulb;
      case VoiceMicState.error:
        return Icons.mic_off;
      case VoiceMicState.idle:
        return Icons.mic_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getButtonColor();
    final icon = _getIcon();

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final scale = _state == VoiceMicState.listening
            ? 1.0 + (_animController.value * 0.14)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: _state == VoiceMicState.listening ? 0.45 : 0.25),
                        blurRadius: _state == VoiceMicState.listening ? 22 : 10,
                        spreadRadius: _state == VoiceMicState.listening ? 5 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _state == VoiceMicState.listening
                    ? 'Đang nghe...'
                    : _state == VoiceMicState.hintShown
                        ? 'Gợi ý!'
                        : _state == VoiceMicState.processing
                            ? 'Xử lý...'
                            : 'Bấm để nói',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
