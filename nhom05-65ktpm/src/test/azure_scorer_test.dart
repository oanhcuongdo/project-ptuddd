import 'dart:convert';
import 'dart:typed_data';

import 'package:english_pronunciation_app/scoring/azure_scorer.dart';
import 'package:english_pronunciation_app/scoring/feedback.dart';
import 'package:english_pronunciation_app/scoring/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> ph(String p, num s) => {'Phoneme': p, 'AccuracyScore': s};

// REST short-audio shape: "I think three" with /θ/ in "think" mispronounced
// and "three" left out.
final restJson = <String, dynamic>{
  'RecognitionStatus': 'Success',
  'DisplayText': 'I sink.',
  'NBest': [
    {
      'Confidence': 0.91,
      'Lexical': 'i sink',
      'AccuracyScore': 62.0,
      'PronScore': 58.4,
      'Words': [
        {'Word': 'i', 'AccuracyScore': 98.0, 'ErrorType': 'None', 'Phonemes': [ph('ay', 98)]},
        {
          'Word': 'think',
          'AccuracyScore': 55.0,
          'ErrorType': 'Mispronunciation',
          'Phonemes': [ph('th', 12), ph('ih', 90), ph('ng', 85), ph('k', 88)],
        },
        {'Word': 'um', 'AccuracyScore': 0, 'ErrorType': 'Insertion'},
        {'Word': 'three', 'AccuracyScore': 0, 'ErrorType': 'Omission'},
      ],
    }
  ],
};

void main() {
  test('maps Azure scores onto our phonemes', () {
    final r = parseAzureResult('I think three', restJson);
    expect(r.source, ScoreSource.azure);
    expect(r.score, 58);
    expect(r.recognizedText, 'i sink');
    expect(r.words.map((w) => w.word), ['i', 'think', 'three']);
    expect(r.words[1].correct, [false, true, true, true]);
    expect(r.words[1].score, 55);
    expect(r.words[2].correct, everyElement(isFalse));
  });

  test('errors feed the existing suggestions', () {
    final r = parseAzureResult('I think three', restJson);
    final th = r.errors.firstWhere((e) => e.word == 'think');
    expect(th.expected, 'TH');
    expect(th.describe, '/θ/ chưa chuẩn');
    expect(r.errors.where((e) => e.word == 'three').every((e) => e.type == ErrorType.deletion),
        isTrue);
    expect(suggestionsFor(r).first.lessonId, 'th');
  });

  test('accepts SDK-style nested scores', () {
    final json = {
      'RecognitionStatus': 'Success',
      'NBest': [
        {
          'Lexical': 'think',
          'PronunciationAssessment': {'PronScore': 91.0},
          'Words': [
            {
              'Word': 'think',
              'PronunciationAssessment': {'AccuracyScore': 91.0, 'ErrorType': 'None'},
              'Phonemes': [
                for (final p in ['th', 'ih', 'ng', 'k'])
                  {'Phoneme': p, 'PronunciationAssessment': {'AccuracyScore': 91.0}},
              ],
            }
          ],
        }
      ],
    };
    final r = parseAzureResult('think', json);
    expect(r.score, 91);
    expect(r.errors, isEmpty);
  });

  test('phoneme count mismatch falls back to the word score', () {
    final json = {
      'RecognitionStatus': 'Success',
      'NBest': [
        {
          'PronScore': 40,
          'Words': [
            {'Word': 'think', 'AccuracyScore': 40, 'ErrorType': 'Mispronunciation', 'Phonemes': [ph('th', 90)]},
          ],
        }
      ],
    };
    expect(parseAzureResult('think', json).words.single.correct, everyElement(isFalse));
  });

  group('scoreAttempt', () {
    final wav = Uint8List(32);

    test('uses Azure when key and recording are present', () async {
      late http.Request sent;
      final client = MockClient((req) async {
        sent = req;
        return http.Response.bytes(utf8.encode(jsonEncode(restJson)), 200);
      });
      final r = await scoreAttempt('I think three', 'i sink',
          wav: wav, key: 'k', region: 'southeastasia', client: client);
      expect(r.source, ScoreSource.azure);
      expect(sent.url.host, 'southeastasia.stt.speech.microsoft.com');
      expect(sent.headers['Ocp-Apim-Subscription-Key'], 'k');
      final cfg = jsonDecode(utf8.decode(base64Decode(sent.headers['Pronunciation-Assessment']!)));
      expect(cfg['ReferenceText'], 'I think three');
      expect(cfg['Granularity'], 'Phoneme');
    });

    test('falls back offline on HTTP error', () async {
      final client = MockClient((_) async => http.Response('quota', 429));
      final r = await scoreAttempt('think', 'sink',
          wav: wav, key: 'k', region: 'southeastasia', client: client);
      expect(r.source, ScoreSource.offline);
      expect(r.errors.single.actual, 'S');
    });

    test('falls back offline when nothing was recognized', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'RecognitionStatus': 'NoMatch'}), 200));
      final r = await scoreAttempt('think', 'think',
          wav: wav, key: 'k', region: 'southeastasia', client: client);
      expect(r.source, ScoreSource.offline);
      expect(r.score, 100);
    });

    test('offline without key or recording', () async {
      final client = MockClient((_) async => fail('must not call Azure'));
      expect((await scoreAttempt('think', 'think', wav: wav, client: client, key: '')).source,
          ScoreSource.offline);
      expect((await scoreAttempt('think', 'think', key: 'k', region: 'r', client: client)).source,
          ScoreSource.offline);
    });
  });
}
