import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/core/services/ai_client.dart';

typedef _Handler = Future<AiHttpResponse> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

class _RecordingTransport implements AiTransport {
  _RecordingTransport(this._handler);

  final _Handler _handler;
  final List<Map<String, String>> headers = <Map<String, String>>[];
  final List<String> bodies = <String>[];
  bool closed = false;

  @override
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) {
    this.headers.add(headers);
    bodies.add(body);
    return _handler(uri, headers, body);
  }

  @override
  void close() => closed = true;
}

AiClient _client(
  _Handler handler, {
  Duration timeout = const Duration(seconds: 15),
  Future<String?> Function()? idTokenProvider,
}) {
  return AiClient(
    endpoint: Uri.parse('https://proxy.test/summarize'),
    transport: _RecordingTransport(handler),
    timeout: timeout,
    idTokenProvider: idTokenProvider,
  );
}

AiHttpResponse _ok(String summary) {
  return AiHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{'summary': summary}),
  );
}

Matcher _failsWith(AiFailureKind kind) {
  return throwsA(
    isA<AiFailure>().having((AiFailure failure) => failure.kind, 'kind', kind),
  );
}

void main() {
  group('AiClient.summarize', () {
    test('gửi đúng nội dung và đọc được {"summary"}', () async {
      late String sentBody;
      final client = _client((_, _, String body) async {
        sentBody = body;
        return _ok('Bản tóm tắt ngắn.');
      });

      final result = await client.summarize(
        text: 'Nội dung ghi chú',
        mode: 'short',
        noteId: 'note-1',
        title: 'Giải tích',
      );

      expect(result, 'Bản tóm tắt ngắn.');
      final payload = jsonDecode(sentBody) as Map<String, dynamic>;
      expect(payload['text'], 'Nội dung ghi chú');
      expect(payload['mode'], 'short');
      expect(payload['noteId'], 'note-1');
      expect(payload['title'], 'Giải tích');
    });

    test('gắn token Firebase vào header Authorization', () async {
      final transport = _RecordingTransport((_, _, _) async => _ok('ok'));
      final client = AiClient(
        endpoint: Uri.parse('https://proxy.test/summarize'),
        transport: transport,
        idTokenProvider: () async => 'firebase-token',
      );

      await client.summarize(text: 'Nội dung', mode: 'long');

      expect(
        transport.headers.single['Authorization'],
        'Bearer firebase-token',
      );
    });

    test('token trả về sau thời hạn thì không gửi yêu cầu tóm tắt', () async {
      final token = Completer<String?>();
      final transport = _RecordingTransport((_, _, _) async => _ok('ok'));
      final client = AiClient(
        endpoint: Uri.parse('https://proxy.test/summarize'),
        transport: transport,
        timeout: const Duration(milliseconds: 15),
        idTokenProvider: () => token.future,
      );

      await expectLater(
        client.summarize(text: 'Nội dung', mode: 'short'),
        _failsWith(AiFailureKind.timeout),
      );
      token.complete('token-đến-muộn');
      await Future<void>.delayed(Duration.zero);
      expect(transport.bodies, isEmpty);
    });

    test('không gửi Authorization khi chưa đăng nhập', () async {
      final transport = _RecordingTransport((_, _, _) async => _ok('ok'));
      final client = AiClient(
        endpoint: Uri.parse('https://proxy.test/summarize'),
        transport: transport,
      );

      await client.summarize(text: 'Nội dung', mode: 'long');

      expect(transport.headers.single.containsKey('Authorization'), isFalse);
    });

    test('chấp nhận {"content"} và {"data": {"summary"}}', () async {
      final contentClient = _client(
        (_, _, _) async => AiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{'content': 'Từ content'}),
        ),
      );
      final nestedClient = _client(
        (_, _, _) async => AiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{
            'data': <String, Object?>{'summary': 'Từ data'},
          }),
        ),
      );

      expect(
        await contentClient.summarize(text: 'x', mode: 'short'),
        'Từ content',
      );
      expect(await nestedClient.summarize(text: 'x', mode: 'short'), 'Từ data');
    });

    test('chấp nhận văn bản thuần', () async {
      final client = _client(
        (_, _, _) async =>
            const AiHttpResponse(statusCode: 200, body: 'Tóm tắt dạng văn bản'),
      );

      expect(
        await client.summarize(text: 'x', mode: 'short'),
        'Tóm tắt dạng văn bản',
      );
    });

    test('HTTP 429 báo hết lượt gọi', () async {
      final client = _client(
        (_, _, _) async => const AiHttpResponse(statusCode: 429, body: 'quota'),
      );

      await expectLater(
        client.summarize(text: 'x', mode: 'short'),
        _failsWith(AiFailureKind.quotaExceeded),
      );
    });

    test('HTTP 401 báo phiên hết hạn', () async {
      final client = _client(
        (_, _, _) async => const AiHttpResponse(statusCode: 401, body: ''),
      );

      await expectLater(
        client.summarize(text: 'x', mode: 'short'),
        _failsWith(AiFailureKind.unauthorized),
      );
    });

    test('HTTP 500 báo lỗi máy chủ', () async {
      final client = _client(
        (_, _, _) async => const AiHttpResponse(statusCode: 500, body: ''),
      );

      await expectLater(
        client.summarize(text: 'x', mode: 'short'),
        _failsWith(AiFailureKind.server),
      );
    });

    test('mất mạng thành lỗi network', () async {
      final client = _client((_, _, _) async {
        throw const SocketException('offline');
      });

      await expectLater(
        client.summarize(text: 'x', mode: 'short'),
        throwsA(
          isA<AiFailure>()
              .having(
                (AiFailure failure) => failure.kind,
                'kind',
                AiFailureKind.network,
              )
              .having(
                (AiFailure failure) => failure.isNetworkError,
                'isNetworkError',
                isTrue,
              ),
        ),
      );
    });

    test('quá thời gian chờ thành lỗi timeout', () async {
      final never = Completer<AiHttpResponse>();
      final client = _client(
        (_, _, _) => never.future,
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        client.summarize(text: 'x', mode: 'short'),
        _failsWith(AiFailureKind.timeout),
      );
    });

    test('ghi chú rỗng không gọi máy chủ', () async {
      final transport = _RecordingTransport((_, _, _) async => _ok('ok'));
      final client = AiClient(
        endpoint: Uri.parse('https://proxy.test/summarize'),
        transport: transport,
      );

      await expectLater(
        client.summarize(text: '   ', mode: 'short'),
        _failsWith(AiFailureKind.emptyContent),
      );
      expect(transport.bodies, isEmpty);
    });

    test('chưa cấu hình endpoint báo lỗi rõ ràng', () async {
      final client = AiClient(
        endpoint: null,
        transport: _RecordingTransport((_, _, _) async => _ok('ok')),
      );

      expect(client.isConfigured, isFalse);
      await expectLater(
        client.summarize(text: 'x', mode: 'short'),
        _failsWith(AiFailureKind.notConfigured),
      );
    });
  });

  group('AiClient.generateQuiz', () {
    test('gửi mode quiz và đọc câu hỏi, đáp án, giải thích', () async {
      late String sentBody;
      final questions = List<Map<String, Object?>>.generate(
        5,
        (int index) => <String, Object?>{
          'question': 'Câu ${index + 1}',
          'options': <String>['A', 'B', 'C', 'D'],
          'correctIndex': 1,
          'explanation': 'Giải thích',
        },
      );
      final client = _client((_, _, String body) async {
        sentBody = body;
        return AiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{'quiz': questions}),
        );
      });

      final result = await client.generateQuiz(
        text: 'Nội dung đủ dài',
        noteId: 'note-1',
        title: 'Sinh học',
      );

      expect(result, hasLength(5));
      expect(result.first['explanation'], 'Giải thích');
      final payload = jsonDecode(sentBody) as Map<String, dynamic>;
      expect(payload['mode'], 'quiz');
      expect(payload['noteId'], 'note-1');
      expect(payload['title'], 'Sinh học');
    });

    test('từ chối phản hồi thiếu câu hỏi hoặc đáp án hợp lệ', () async {
      final shortListClient = _client(
        (_, _, _) async => AiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{'quiz': <Object?>[]}),
        ),
      );
      final invalidOptionsClient = _client(
        (_, _, _) async => AiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{
            'quiz': List<Map<String, Object?>>.generate(
              5,
              (int index) => <String, Object?>{
                'question': 'Câu $index',
                'options': <String>['A', 'A', 'C', 'D'],
                'correctIndex': 0,
                'explanation': 'Giải thích',
              },
            ),
          }),
        ),
      );

      await expectLater(
        shortListClient.generateQuiz(text: 'Nội dung', noteId: '1', title: 'T'),
        _failsWith(AiFailureKind.badResponse),
      );
      await expectLater(
        invalidOptionsClient.generateQuiz(
          text: 'Nội dung',
          noteId: '1',
          title: 'T',
        ),
        _failsWith(AiFailureKind.badResponse),
      );
    });

    test('hiển thị lỗi máy chủ đúng tên tính năng trắc nghiệm', () async {
      final client = _client(
        (_, _, _) async => const AiHttpResponse(statusCode: 500, body: ''),
      );

      await expectLater(
        client.generateQuiz(text: 'Nội dung', noteId: '1', title: 'T'),
        throwsA(
          isA<AiFailure>().having(
            (AiFailure failure) => failure.message,
            'message',
            contains('Máy chủ trắc nghiệm'),
          ),
        ),
      );
    });
  });

  group('AiClient.demo', () {
    test('tóm tắt cục bộ theo ba kiểu, không cần mạng', () async {
      final client = AiClient.demo();
      const text =
          'Đạo hàm mô tả tốc độ thay đổi. Tích phân tính diện tích. '
          'Ứng dụng trong kinh tế. Cần ôn lại quy tắc chuỗi.';

      final short = await client.summarize(text: text, mode: 'short');
      final long = await client.summarize(text: text, mode: 'long');
      final bullets = await client.summarize(text: text, mode: 'bullets');

      expect(client.isDemo, isTrue);
      expect(short, isNotEmpty);
      expect(long.length, greaterThanOrEqualTo(short.length));
      expect(bullets.split('\n').length, greaterThan(1));
      expect(bullets, contains('•'));
    });
  });
}
