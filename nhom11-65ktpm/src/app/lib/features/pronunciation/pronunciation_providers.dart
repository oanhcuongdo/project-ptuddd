import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/contracts/lesson_repository.dart';
import '../../../core/contracts/pronunciation_scorer.dart';
import '../../../core/contracts/speech_services.dart';
import '../../../core/network/api_client.dart';
import 'data/real_voice_recorder.dart';
import 'engine/cedict_pinyin_service.dart';
import 'engine/hybrid_pronunciation_scorer.dart';
import 'engine/offline_pronunciation_engine.dart';

final realVoiceRecorderProvider = Provider<VoiceRecorder>((ref) {
  final r = RealVoiceRecorder();
  ref.onDispose(r.dispose);
  return r;
});

final cedictPinyinServiceProvider = Provider<PinyinService>((ref) {
  return CedictPinyinService(ref.watch(lessonRepositoryProvider));
});

final offlinePronunciationEngineProvider = Provider<OfflinePronunciationEngine>((ref) {
  return OfflinePronunciationEngine();
});

final hybridPronunciationScorerProvider = Provider<PronunciationScorer>((ref) {
  final mode = ref.watch(scoringModeProvider);
  final client = ref.watch(apiClientProvider);
  return HybridPronunciationScorer(
    getScoringMode: () => mode,
    apiClient: client,
    serverBaseUrl: AppConstants.defaultBaseUrl,
  );
});
