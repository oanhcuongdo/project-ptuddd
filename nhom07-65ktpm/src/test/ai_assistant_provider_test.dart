import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dcsleep/data/database/database_helper.dart';
import 'package:dcsleep/data/models/ai_message_model.dart';
import 'package:dcsleep/data/services/ai_service.dart';
import 'package:dcsleep/data/services/api_key_manager.dart';
import 'package:dcsleep/providers/ai_assistant_provider.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  final List<AIMessageModel> storedMessages = [];
  int insertCallCount = 0;
  int clearCallCount = 0;
  int _nextId = 1;

  @override
  Future<List<AIMessageModel>> getAllAIMessages() async {
    return List<AIMessageModel>.from(storedMessages);
  }

  @override
  Future<int> insertAIMessage(AIMessageModel msg) async {
    insertCallCount++;
    final id = _nextId++;
    storedMessages.add(
      AIMessageModel(
        id: id,
        text: msg.text,
        isUser: msg.isUser,
        isOffline: msg.isOffline,
        timestamp: msg.timestamp,
      ),
    );
    return id;
  }

  @override
  Future<int> clearAllAIMessages() async {
    clearCallCount++;
    final count = storedMessages.length;
    storedMessages.clear();
    return count;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected DB call: ${invocation.memberName}');
}

class FakeAIService implements AIService {
  String _apiKey = '';
  int askCallCount = 0;
  String? capturedPrompt;
  String? capturedSleepContext;
  List<AIMessageModel>? capturedHistory;
  Object? errorToThrow;
  String responseToReturn = 'Phản hồi từ AI trực tuyến';

  @override
  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  @override
  void setApiKey(String key) {
    _apiKey = key;
  }

  @override
  Future<String> askAssistant({
    required String prompt,
    String? sleepContext,
    List<AIMessageModel> history = const [],
  }) async {
    askCallCount++;
    capturedPrompt = prompt;
    capturedSleepContext = sleepContext;
    capturedHistory = List<AIMessageModel>.from(history);

    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return responseToReturn;
  }
}

class FakeApiKeyManager implements ApiKeyManager {
  String keyToReturn = 'fake_gemini_api_key';
  Object? errorToThrow;

  @override
  Future<String> getApiKey() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return keyToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected ApiKeyManager call: ${invocation.memberName}',
  );
}

void main() {
  late FakeDatabaseHelper fakeDb;
  late FakeAIService fakeAiService;
  late FakeApiKeyManager fakeKeyManager;
  late AIAssistantProvider provider;

  setUp(() {
    fakeDb = FakeDatabaseHelper();
    fakeAiService = FakeAIService();
    fakeKeyManager = FakeApiKeyManager();
    provider = AIAssistantProvider(
      databaseHelper: fakeDb,
      aiService: fakeAiService,
      apiKeyManager: fakeKeyManager,
      enableNetworkListener: false,
    );
  });

  group('AIAssistantProvider Tests', () {
    test('1. Debounce: ignores duplicate send when isThinking is true and ignores empty input', () async {
      provider.setThinkingForTest(true);
      await provider.sendMessage('Test prompt');

      expect(provider.messages.isEmpty, true);
      expect(fakeDb.insertCallCount, 0);
      expect(fakeAiService.askCallCount, 0);

      provider.setThinkingForTest(false);
      await provider.sendMessage('   ');

      expect(provider.messages.isEmpty, true);
      expect(fakeDb.insertCallCount, 0);
      expect(fakeAiService.askCallCount, 0);
    });

    test('2. SafetyGuardrails Pre-filter blocks unsafe prompt, keeps isOffline = false, and resets isThinking', () async {
      await provider.sendMessage('Uong thuoc ngu');

      expect(fakeAiService.askCallCount, 0);
      expect(provider.messages.length, 2);
      expect(provider.messages.first.isUser, true);
      expect(provider.messages.last.isUser, false);
      expect(provider.messages.last.isOffline, false);
      expect(provider.isOfflineMode, false);
      expect(provider.isThinking, false);
      expect(provider.isLoading, false);
    });

    test('3. Online success trims prompt, captures previousHistory before userMsg, passes sleepContext, and auto-recovers', () async {
      fakeDb.storedMessages.add(
        AIMessageModel(id: 1, text: 'Xin chào', isUser: false),
      );
      await provider.loadMessages();

      provider.setOfflineModeForTest(true, reason: 'Mất mạng');
      fakeAiService.responseToReturn = 'Bạn nên ngủ 7-8 giờ mỗi đêm.';

      await provider.sendMessage(
        '  Nên ngủ mấy giờ  ',
        sleepSummary: 'Mục tiêu: 8.0h.',
      );

      expect(fakeAiService.askCallCount, 1);
      expect(fakeAiService.capturedPrompt, 'Nên ngủ mấy giờ');
      expect(fakeAiService.capturedSleepContext, 'Mục tiêu: 8.0h.');
      expect(fakeAiService.capturedHistory?.length, 1);
      expect(
        fakeAiService.capturedHistory?.any((m) => m.text == 'Nên ngủ mấy giờ'),
        false,
      );

      expect(provider.messages.last.text, 'Bạn nên ngủ 7-8 giờ mỗi đêm.');
      expect(provider.messages.last.isOffline, false);
      expect(provider.isOfflineMode, false);
      expect(provider.offlineReason, isNull);
      expect(provider.isThinking, false);
    });

    test('4. API error on HTTP 429 and 503 sets apiError without activating offline fallback', () async {
      fakeAiService.errorToThrow = AIServiceException(
        'Rate limit exceeded',
        statusCode: 429,
      );

      await provider.sendMessage('Ngủ trưa bao lâu?');

      expect(provider.isOfflineMode, false);
      expect(provider.apiError, contains('429'));
      expect(provider.isThinking, false);

      fakeAiService.errorToThrow = AIServiceException(
        'Server Unavailable',
        statusCode: 503,
      );

      await provider.sendMessage('Nhiệt độ phòng ngủ');
      expect(provider.isOfflineMode, false);
      expect(provider.apiError, contains('503'));
    });

    test('5. Error classification: HTTP 401 sets apiError, SocketException activates offline fallback with sleepContext', () async {
      // HTTP 401: Lỗi API -> apiError
      fakeAiService.errorToThrow = AIServiceException(
        'Unauthorized',
        statusCode: 401,
      );
      await provider.sendMessage('Thở 4-7-8');
      expect(provider.isOfflineMode, false);
      expect(provider.apiError, contains('không hợp lệ'));

      // TimeoutException -> apiError
      fakeAiService.errorToThrow = TimeoutException('Exceeded 10s');
      await provider.sendMessage('Uống cà phê sau mấy giờ?');
      expect(provider.isOfflineMode, false);
      expect(provider.apiError, contains('quá chậm'));

      // SocketException -> Lỗi mạng thật -> isOfflineMode = true + OfflineSleepEngine
      fakeAiService.errorToThrow = const SocketException('No internet');
      await provider.sendMessage(
        'Đánh giá tiến độ giấc ngủ',
        sleepSummary: 'Tỷ lệ tuân thủ: 72%.',
      );
      expect(provider.isOfflineMode, true);
      expect(provider.offlineReason, contains('Mất kết nối Internet'));
      expect(provider.messages.last.isOffline, true);
      expect(provider.messages.last.text, contains('72%'));
      expect(provider.isThinking, false);
    });

    test('6. ApiKeyManager Keystore exception gracefully sets apiError without crashing', () async {
      fakeKeyManager.errorToThrow = Exception('Keystore failure');

      await provider.sendMessage('Khó ngủ trằn trọc');

      expect(fakeAiService.askCallCount, 0);
      expect(provider.isOfflineMode, false);
      expect(provider.apiError, isNotNull);
      expect(provider.isThinking, false);
    });

    test('7. loadMessages and clearHistory use injected DatabaseHelper cleanly', () async {
      fakeDb.storedMessages.addAll([
        AIMessageModel(id: 1, text: 'Chào bạn', isUser: false),
        AIMessageModel(id: 2, text: 'Tôi khó ngủ', isUser: true),
      ]);

      await provider.loadMessages();
      expect(provider.messages.length, 2);
      expect(provider.messages[1].text, 'Tôi khó ngủ');

      await provider.clearHistory();
      expect(fakeDb.clearCallCount, 1);
      expect(fakeDb.storedMessages.isEmpty, true);
      expect(provider.messages.isEmpty, true);
    });
  });
}
