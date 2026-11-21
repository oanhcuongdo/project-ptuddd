import 'package:flutter_test/flutter_test.dart';
import 'package:chailish/core/network/api_client.dart';
import 'package:chailish/core/storage/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('ApiClient Tests', () {
    test('handles 200 OK response successfully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"status": "ok", "message": "success"}', 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final storage = SecureStorageService(const FlutterSecureStorage());
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000/api',
        storage: storage,
        client: mockClient,
      );

      final result = await apiClient.get('/test', requireAuth: false);
      expect(result['status'], 'ok');
      expect(result['message'], 'success');
    });

    test('throws UnauthorizedException on 401 when refresh fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Token expired"}', 401);
      });

      final storage = SecureStorageService(const FlutterSecureStorage());
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000/api',
        storage: storage,
        client: mockClient,
      );

      expect(
        () async => await apiClient.get('/protected', requireAuth: true),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws ApiException on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Not found"}', 404);
      });

      final storage = SecureStorageService(const FlutterSecureStorage());
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000/api',
        storage: storage,
        client: mockClient,
      );

      expect(
        () async => await apiClient.get('/not-found', requireAuth: false),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
