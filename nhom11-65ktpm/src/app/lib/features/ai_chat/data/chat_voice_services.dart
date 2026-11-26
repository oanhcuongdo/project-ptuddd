import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/speech_services.dart';

/// Đọc mẫu câu tiếng Trung cho màn hình trò chuyện AI: dùng dịch vụ TTS chung
/// (`core/contracts/speech_services.dart`, chủ sở hữu Khánh #12).
typedef ChatTts = TtsService;

/// Nhận dạng giọng nói zh-CN để người học trả lời bằng cách nói (dịch vụ chung #11).
typedef ChatSpeechInput = SpeechRecognizer;

/// Giữ tên cũ để test có thể override riêng cho màn chat.
final chatTtsProvider = Provider<ChatTts>((ref) => ref.watch(ttsServiceProvider));

final chatSpeechInputProvider = Provider<ChatSpeechInput>((ref) => ref.watch(speechRecognizerProvider));
