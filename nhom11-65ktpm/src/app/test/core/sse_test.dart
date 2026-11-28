import 'dart:convert';

import 'package:chailish/core/network/api_client.dart';
import 'package:chailish/core/network/sse.dart';
import 'package:chailish/core/storage/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _body = 'event: user_message\ndata: {"id": "u1"}\n\n'
    ': keep-alive comment\n\n'
    'event: delta\ndata: {"text": "你好"}\n\n'
    'event: delta\ndata: {"text": "！你是学生吗？"}\n\n'
    'event: done\ndata: {"turn_count": 1}\n\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseSse', () {
    test('parses events even when UTF-8 bytes are split across chunks', () async {
      final bytes = utf8.encode(_body);
      // Cắt mỗi 5 byte -> nhiều chữ Hán bị cắt giữa hai gói.
      final chunks = [for (var i = 0; i < bytes.length; i += 5) bytes.sublist(i, (i + 5).clamp(0, bytes.length))];
      final events = await parseSse(Stream.fromIterable(chunks)).toList();

      expect(events.map((e) => e.event), ['user_message', 'delta', 'delta', 'done']);
      expect(events[1].json['text'], '你好');
      expect(events.where((e) => e.event == 'delta').map((e) => e.json['text']).join(), '你好！你是学生吗？');
    });

    test('joins multi-line data and flushes the last event without blank line', () async {
      final events = await parseSse(Stream.value(utf8.encode('data: a\ndata: b'))).toList();
      expect(events.single.event, 'message');
      expect(events.single.data, 'a\nb');
    });
  });

  group('ApiClient.postStream', () {
    test('streams events with auth header and refreshes token on 401', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureStorageService(const FlutterSecureStorage());
      await storage.saveToken('old');
      await storage.saveRefreshToken('refresh-1');

      final client = MockClient.streaming((request, bodyStream) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.StreamedResponse(
            Stream.value(utf8.encode('{"access_token": "new", "refresh_token": "refresh-2"}')),
            200,
          );
        }
        if (request.headers['Authorization'] != 'Bearer new') {
          return http.StreamedResponse(Stream.value(utf8.encode('{"detail": "expired"}')), 401);
        }
        expect(request.headers['Accept'], 'text/event-stream');
        return http.StreamedResponse(Stream.value(utf8.encode(_body)), 200);
      });

      final api = ApiClient(baseUrl: 'http://x/api', storage: storage, client: client);
      final events = await api.postStream('/ai/conversations/c1/messages', body: {'content': '你好'}).toList();
      expect(events.length, 4);
      expect(await storage.getRefreshToken(), 'refresh-2');
    });

    test('throws ApiException with server detail on 429', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureStorageService(const FlutterSecureStorage());
      final client = MockClient.streaming((request, _) async => http.StreamedResponse(
            Stream.value(utf8.encode('{"detail": "Bạn đã dùng hết lượt hôm nay"}')),
            429,
          ));
      final api = ApiClient(baseUrl: 'http://x/api', storage: storage, client: client);

      await expectLater(
        api.postStream('/ai/conversations/c1/messages').toList(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having((e) => e.message, 'message', 'Bạn đã dùng hết lượt hôm nay')),
      );
    });
  });
}
