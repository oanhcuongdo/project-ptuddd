import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/vietnamese_number_extractor.dart';

enum VoiceMicState {
  idle,
  listening,
  processing,
  hintShown,
  unavailable,
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

/// Alias cho VoiceAnswerMicButton theo đặc tả 7.7
typedef AiMicButton = VoiceAnswerMicButton;

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
      duration: const Duration(milliseconds: 1000),
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

  AudioService? _getAudioService() {
    try {
      if (sl.isRegistered<AudioService>()) {
        return sl<AudioService>();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _toggleListening() async {
    if (_state == VoiceMicState.listening || _speech.isListening) {
      await _speech.stop();
      _setState(VoiceMicState.idle);
      widget.onStatusChanged?.call('Đã dừng nghe.');
      return;
    }

    bool available = false;
    try {
      available = await _speech.initialize(
        onError: (val) {
          if (!mounted) return;
          _setState(VoiceMicState.error);
          widget.onStatusChanged
              ?.call('Lỗi nhận diện giọng nói: ${val.errorMsg}');
          widget.onError?.call(val.errorMsg);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _state == VoiceMicState.error) {
              _setState(VoiceMicState.idle);
            }
          });
        },
        onStatus: (val) {
          if (!mounted) return;
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

    if (!mounted) return;

    if (available) {
      if (_speech.isListening) {
        await _speech.stop();
      }
      _setState(VoiceMicState.listening);
      _recognizedWords = '';
      widget.onStatusChanged?.call('Đang lắng nghe bé nói...');

      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'vi_VN',
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 4),
        ),
        onResult: (result) {
          if (!mounted) return;
          _recognizedWords = result.recognizedWords;
          widget.onStatusChanged?.call('Bé vừa nói: "$_recognizedWords"');

          final extraction =
              VietnameseNumberExtractor.extract(_recognizedWords);

          // 1. Nếu bé nói "con không biết", "chịu", "khó quá", "bỏ qua" -> Kích hoạt gợi ý
          if (extraction.isUnknown) {
            _speech.stop();
            _setState(VoiceMicState.hintShown);

            // Đọc phản hồi thân thiện bằng giọng nói tiếng Việt (vi-VN)
            _getAudioService()
                ?.speak('Không sao đâu bé nhé, cùng xem gợi ý nào!');

            widget.onStatusChanged
                ?.call('Đừng lo bé nhé! Xem gợi ý thị phạm nào! 💡');
            widget.onHintRequested?.call(_recognizedWords);

            Future.delayed(const Duration(milliseconds: 2500), () {
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

  /// Hộp thoại mô phỏng phát ngôn trực quan giúp test nhanh trên Desktop/Web
  void _showVoiceSimulationDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Text('🎙️ ', style: TextStyle(fontSize: 26)),
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
                'Bé hãy đọc hoặc nhập đáp án vào đây nhé:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: "dạ bằng 25 ạ" hoặc "con không biết"',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _quickPhraseChip(textController, 'dạ bằng năm'),
                  _quickPhraseChip(textController, 'mười lăm ạ'),
                  _quickPhraseChip(textController, 'hai nhăm'),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final text = textController.text.trim();
                Navigator.pop(context);
                final extraction = VietnameseNumberExtractor.extract(text);

                if (extraction.isUnknown) {
                  _setState(VoiceMicState.hintShown);
                  _getAudioService()
                      ?.speak('Không sao đâu bé nhé, cùng xem gợi ý nào!');
                  widget.onHintRequested?.call(text);
                  Future.delayed(const Duration(milliseconds: 2500), () {
                    if (mounted) _setState(VoiceMicState.idle);
                  });
                } else if (extraction.isNumber && extraction.value != null) {
                  widget.onAnswerDetected(extraction.value!, text);
                } else {
                  _setState(VoiceMicState.idle);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Không tìm thấy số 0-99 trong câu: "$text"'),
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
      case VoiceMicState.unavailable:
        return Colors.blueGrey;
      case VoiceMicState.error:
        return Colors.red.shade700;
      case VoiceMicState.idle:
        return AppColors.primary;
    }
  }

  IconData _getIcon() {
    switch (_state) {
      case VoiceMicState.listening:
        return Icons.mic_rounded;
      case VoiceMicState.processing:
        return Icons.hourglass_top_rounded;
      case VoiceMicState.hintShown:
        return Icons.lightbulb;
      case VoiceMicState.unavailable:
        return Icons.mic_off_rounded;
      case VoiceMicState.error:
        return Icons.error_outline_rounded;
      case VoiceMicState.idle:
        return Icons.mic_none_rounded;
    }
  }

  String _getStatusText() {
    switch (_state) {
      case VoiceMicState.listening:
        return 'Đang nghe...';
      case VoiceMicState.hintShown:
        return '💡 Gợi ý!';
      case VoiceMicState.processing:
        return 'Đang xử lý...';
      case VoiceMicState.unavailable:
        return 'Chưa có quyền mic';
      case VoiceMicState.error:
        return 'Thử lại';
      case VoiceMicState.idle:
        return 'Bấm để nói';
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
                        color: color.withValues(
                            alpha: _state == VoiceMicState.listening
                                ? 0.45
                                : 0.25),
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
                _getStatusText(),
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
