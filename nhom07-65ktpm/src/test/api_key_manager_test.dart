import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dcsleep/data/services/api_key_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('ApiKeyManager Tests', () {
    test('ApiKeyManager fallback to environment key when storage is empty', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final manager = ApiKeyManager();
      final key = await manager.getApiKey();
      expect(key, isA<String>());
      expect(await manager.hasCustomApiKey(), false);
    });

    test('ApiKeyManager saves custom key to secure storage and retrieves it with highest priority', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final manager = ApiKeyManager();

      await manager.saveCustomApiKey('AQ.TestSecretKey12345');
      final key = await manager.getApiKey();

      expect(key, 'AQ.TestSecretKey12345');
      expect(await manager.hasCustomApiKey(), true);
    });

    test('ApiKeyManager trims whitespace from saved key', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final manager = ApiKeyManager();

      await manager.saveCustomApiKey('   AQ.KeyWithSpaces   ');
      final key = await manager.getApiKey();

      expect(key, 'AQ.KeyWithSpaces');
    });

    test('ApiKeyManager clears custom key from storage and reverts to environment key', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final manager = ApiKeyManager();

      await manager.saveCustomApiKey('AQ.CustomKeyToDelete');
      expect(await manager.hasCustomApiKey(), true);

      await manager.clearCustomApiKey();
      expect(await manager.hasCustomApiKey(), false);

      final key = await manager.getApiKey();
      // Should revert to environment key (or empty if none provided in test environment)
      expect(key != 'AQ.CustomKeyToDelete', true);
    });
  });
}
