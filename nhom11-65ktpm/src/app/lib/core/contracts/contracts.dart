/// Hợp đồng giữa các tính năng: interface + bản giả + provider.
///
/// Quy tắc (chi tiết: docs/lam-viec-song-song.md):
/// - Tính năng chỉ phụ thuộc vào interface ở đây, KHÔNG import file trong
///   `features/<tính năng của người khác>/`.
/// - Mỗi provider mặc định trả bản giả. Chủ sở hữu làm xong bản thật thì đổi
///   provider của mình: `AppConfig.fakeData ? FakeX() : RealX(...)`.
/// - Không đổi chữ ký interface khi chưa báo cả nhóm (sửa luôn bản giả + test).
library;

import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'auth_repository.dart';
import 'hanzi_repository.dart';
import 'lesson_repository.dart';
import 'outbox.dart';
import 'progress_service.dart';
import 'pronunciation_scorer.dart';
import 'speech_services.dart';
import 'srs_service.dart';
import 'path_repository.dart'; 

export '../config/app_config.dart';
export 'auth_repository.dart';
export 'fake_implementation.dart';
export 'fakes/demo_events.dart';
export 'hanzi_repository.dart';
export 'lesson_repository.dart';
export 'models/hanzi.dart';
export 'models/learning_event.dart';
export 'models/lesson.dart';
export 'models/path.dart';    
export 'models/pronunciation.dart';
export 'models/user_profile.dart';
export 'outbox.dart';
export 'path_repository.dart'; 
export 'progress_service.dart';
export 'pronunciation_scorer.dart';
export 'speech_services.dart';
export 'srs_service.dart';

/// Một hợp đồng và người chịu trách nhiệm bản thật (hiện trong menu dev).
class ContractEntry {
  final String name;
  final String owner;
  final String issues;
  final ProviderListenable<Object?> provider;

  const ContractEntry(this.name, this.owner, this.issues, this.provider);
}

final contractEntries = <ContractEntry>[
  ContractEntry('Kho bài học (LessonRepository)', 'Hoa', '#18 #19', lessonRepositoryProvider),
  ContractEntry('Thẻ ôn SM-2 (SrsService)', 'Hoa', '#20', srsServiceProvider),
  ContractEntry('Đọc mẫu (TtsService)', 'Khánh', '#12', ttsServiceProvider),
  ContractEntry('Pinyin (PinyinService)', 'Khánh', '#12', pinyinServiceProvider),
  ContractEntry('Nhận giọng nói (SpeechRecognizer)', 'Khánh', '#11', speechRecognizerProvider),
  ContractEntry('Ghi âm (VoiceRecorder)', 'Khánh', '#11', voiceRecorderProvider),
  ContractEntry('Chấm phát âm (PronunciationScorer)', 'Khánh', '#13 #14', pronunciationScorerProvider),
  ContractEntry('Nét chữ Hán (HanziRepository)', 'Đệ', '#26', hanziRepositoryProvider),
  ContractEntry('Hàng đợi đồng bộ (Outbox)', 'Đệ', '#23 #25', outboxProvider),
  ContractEntry('Sự kiện học tập (ProgressService)', 'Phúc', 'khung', progressServiceProvider),
  ContractEntry('Đăng nhập (AuthRepository)', 'Phúc / Đệ', '#6 #24', authRepositoryProvider),
  ContractEntry('Lộ trình học (PathRepository)', 'Bảo', '#29', pathRepositoryProvider),
];
