import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'phonemes.dart';
import 'pronunciation_scorer.dart';

// shortcut: the key ships inside the APK via --dart-define; move to a
// short-lived token issued by a backend before any public release.
const azureKey = String.fromEnvironment('AZURE_SPEECH_KEY');
const azureRegion = String.fromEnvironment('AZURE_SPEECH_REGION');

/// A phoneme or word scored below this (0–100) counts as wrong.
const azureThreshold = 60;

class AzureException implements Exception {
  final String message;
  const AzureException(this.message);
  @override
  String toString() => 'AzureException: $message';
}

/// Sends a 16 kHz mono PCM WAV recording to Azure Pronunciation Assessment
/// (REST, short audio) and converts the answer to a [PronunciationResult].
Future<PronunciationResult> assessWithAzure(Uint8List wav, String reference,
    {required String key, required String region, http.Client? client}) async {
  final config = base64Encode(utf8.encode(jsonEncode({
    'ReferenceText': reference,
    'GradingSystem': 'HundredMark',
    'Granularity': 'Phoneme',
    'Dimension': 'Comprehensive',
  })));
  final uri = Uri.https('$region.stt.speech.microsoft.com',
      '/speech/recognition/conversation/cognitiveservices/v1',
      {'language': 'en-US', 'format': 'detailed'});
  final c = client ?? http.Client();
  try {
    final res = await c
        .post(uri,
            headers: {
              'Ocp-Apim-Subscription-Key': key,
              'Content-Type': 'audio/wav; codecs=audio/pcm; samplerate=16000',
              'Accept': 'application/json',
              'Pronunciation-Assessment': config,
            },
            body: wav)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw AzureException('HTTP ${res.statusCode}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (json['RecognitionStatus'] != 'Success') {
      throw AzureException('${json['RecognitionStatus']}');
    }
    return parseAzureResult(reference, json);
  } finally {
    if (client == null) c.close();
  }
}

// REST puts scores directly on each object; the Speech SDK nests them under
// "PronunciationAssessment". Accept both.
num? _score(Map m, String k) =>
    (m[k] ?? (m['PronunciationAssessment'] as Map?)?[k]) as num?;

String? _errorType(Map m) =>
    (m['ErrorType'] ?? (m['PronunciationAssessment'] as Map?)?['ErrorType'])
        as String?;

/// Maps Azure's detailed JSON onto the same result shape the offline scorer
/// produces, so feedback, storage and progress screens work unchanged.
/// Phonemes come from our own dictionary; Azure only supplies their scores.
PronunciationResult parseAzureResult(String reference, Map<String, dynamic> json) {
  final best = (json['NBest'] as List).first as Map;
  final refWords = tokenize(reference);
  // Inserted words are not in the reference text, so they have no slot here.
  final azWords = [
    for (final w in (best['Words'] as List? ?? const []).cast<Map>())
      if (_errorType(w) != 'Insertion') w,
  ];

  final words = <WordResult>[];
  final errors = <PhonemeError>[];
  for (var i = 0; i < refWords.length; i++) {
    final word = refWords[i];
    final ps = phonemesOf(word);
    final az = i < azWords.length ? azWords[i] : null;
    final omitted = az == null || _errorType(az) == 'Omission';
    final wordScore = omitted ? 0 : (_score(az, 'AccuracyScore') ?? 0).round();
    final azPs = (az?['Phonemes'] as List? ?? const []).cast<Map>();

    final correct = List<bool>.generate(ps.length, (k) {
      if (omitted) return false;
      // Our dictionary and Azure's phone set usually agree on the count; when
      // they do not, fall back to the word score for every phoneme.
      final s = azPs.length == ps.length ? _score(azPs[k], 'AccuracyScore') : wordScore;
      return (s ?? 0) >= azureThreshold;
    });
    for (var k = 0; k < ps.length; k++) {
      if (correct[k]) continue;
      errors.add(omitted
          ? PhonemeError(i, word, ps[k], null, ErrorType.deletion, false)
          : PhonemeError(i, word, ps[k], null, ErrorType.substitution, k == ps.length - 1));
    }
    words.add(WordResult(word, ps, correct, wordScore));
  }

  final score = _score(best, 'PronScore') ?? _score(best, 'AccuracyScore') ?? 0;
  return PronunciationResult(
    reference,
    (best['Lexical'] ?? best['Display'] ?? json['DisplayText'] ?? '') as String,
    score.round().clamp(0, 100),
    (best['Confidence'] as num?)?.toDouble() ?? 0,
    words,
    errors,
    source: ScoreSource.azure,
  );
}

/// Scores one attempt: Azure when a key is configured and a recording is
/// available, otherwise — or when Azure fails (offline, quota, timeout) —
/// the offline phoneme alignment on what the speech recognizer heard.
Future<PronunciationResult> scoreAttempt(String expected, String recognized,
    {double confidence = 0,
    Uint8List? wav,
    String key = azureKey,
    String region = azureRegion,
    http.Client? client}) async {
  if (wav != null && key.isNotEmpty && region.isNotEmpty) {
    try {
      return await assessWithAzure(wav, expected,
          key: key, region: region, client: client);
    } catch (_) {
      // Fall through: the learner still gets a score without the network.
    }
  }
  return scorePronunciation(expected, recognized, confidence: confidence);
}
