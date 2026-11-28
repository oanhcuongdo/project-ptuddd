import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dcsleep/core/theme/app_theme.dart';
import 'package:dcsleep/data/database/database_helper.dart';
import 'package:dcsleep/data/models/ai_message_model.dart';
import 'package:dcsleep/data/services/ai_service.dart';
import 'package:dcsleep/data/services/api_key_manager.dart';
import 'package:dcsleep/providers/ai_assistant_provider.dart';
import 'package:dcsleep/providers/sleep_provider.dart';
import 'package:dcsleep/screens/ai_assistant/ai_assistant_screen.dart';

class _FakeDatabaseHelper implements DatabaseHelper {
  final List<AIMessageModel> storedMessages = [];

  @override
  Future<List<AIMessageModel>> getAllAIMessages() async =>
      List<AIMessageModel>.from(storedMessages);

  @override
  Future<int> insertAIMessage(AIMessageModel msg) async {
    storedMessages.add(msg);
    return storedMessages.length;
  }

  @override
  Future<int> clearAllAIMessages() async {
    final count = storedMessages.length;
    storedMessages.clear();
    return count;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected DB call: ${invocation.memberName}');
}

class _FakeAIService implements AIService {
  String _key = '';
  String? capturedPrompt;
  String? capturedSleepContext;
  String responseToReturn = 'Trả lời online chuẩn khoa học.';

  @override
  bool get hasApiKey => _key.trim().isNotEmpty;

  @override
  void setApiKey(String key) {
    _key = key;
  }

  @override
  Future<String> askAssistant({
    required String prompt,
    String? sleepContext,
    List<AIMessageModel> history = const [],
  }) async {
    capturedPrompt = prompt;
    capturedSleepContext = sleepContext;
    return responseToReturn;
  }
}

class _FakeApiKeyManager implements ApiKeyManager {
  String storedKey = 'demo_key';
  String? lastSavedKey;
  bool clearCalled = false;

  @override
  Future<String> getApiKey() async => storedKey;

  @override
  Future<void> saveCustomApiKey(String key) async {
    lastSavedKey = key.trim();
    storedKey = key.trim();
  }

  @override
  Future<void> clearCustomApiKey() async {
    clearCalled = true;
    storedKey = '';
  }

  @override
  Future<bool> hasCustomApiKey() async => storedKey.isNotEmpty;

  @override
  Future<bool> hasAnyApiKey() async => storedKey.isNotEmpty;
}

void main() {
  late _FakeDatabaseHelper fakeDb;
  late _FakeAIService fakeAiService;
  late _FakeApiKeyManager fakeKeyManager;
  late AIAssistantProvider aiProvider;
  late SleepProvider sleepProvider;

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AIAssistantProvider>.value(value: aiProvider),
        ChangeNotifierProvider<SleepProvider>.value(value: sleepProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: AIAssistantScreen(apiKeyManager: fakeKeyManager),
      ),
    );
  }

  setUp(() {
    fakeDb = _FakeDatabaseHelper();
    fakeAiService = _FakeAIService();
    fakeKeyManager = _FakeApiKeyManager();
    aiProvider = AIAssistantProvider(
      databaseHelper: fakeDb,
      aiService: fakeAiService,
      apiKeyManager: fakeKeyManager,
      enableNetworkListener: false,
    );
    sleepProvider = SleepProvider();
  });

  group('AIAssistantScreen Widget Tests', () {
    testWidgets('displays offline banner when isOfflineMode is true', (tester) async {
      aiProvider.setOfflineModeForTest(true, reason: 'Mất kết nối Internet');

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.textContaining('Không có kết nối Internet'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('displays apiError banner when apiError is set and allows clearing', (tester) async {
      aiProvider.setApiErrorForTest('Gemini API Key không hợp lệ');

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Gemini API Key không hợp lệ'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(aiProvider.apiError, isNull);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('hides offline banner when online and displays fixed Medical Disclaimer', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.wifi_off), findsNothing);
      expect(
        find.text(
          'DCSleep AI cung cấp kiến thức vệ sinh giấc ngủ nhằm xây dựng thói quen khoa học, không thay thế chẩn đoán y tế.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders [Ngoại tuyến] tag only on offline bot messages', (tester) async {
      fakeDb.storedMessages.addAll([
        AIMessageModel(id: 1, text: 'Câu trả lời online', isUser: false, isOffline: false),
        AIMessageModel(id: 2, text: 'Câu trả lời offline', isUser: false, isOffline: true),
      ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('[Ngoại tuyến]'), findsOneWidget);
      expect(find.text('Câu trả lời online'), findsOneWidget);
      expect(find.text('Câu trả lời offline'), findsOneWidget);
    });

    testWidgets('tapping Quick Chip sends prompt with SleepProvider context summary', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final chipFinder = find.text('Nên ngủ trưa bao nhiêu phút là tốt nhất?');
      expect(chipFinder, findsOneWidget);

      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(fakeAiService.capturedPrompt, 'Nên ngủ trưa bao nhiêu phút là tốt nhất?');
      expect(fakeAiService.capturedSleepContext, contains('8.0h'));
      expect(fakeAiService.capturedSleepContext, contains('100%'));
      expect(find.text('Trả lời online chuẩn khoa học.'), findsOneWidget);
    });

    testWidgets('API Key config dialog saves and clears custom key via ApiKeyManager', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.vpn_key_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Cấu hình Gemini API Key'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'AQ.DemoNewKey999');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(fakeKeyManager.lastSavedKey, 'AQ.DemoNewKey999');

      await tester.tap(find.byIcon(Icons.vpn_key_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xóa key'));
      await tester.pumpAndSettle();

      expect(fakeKeyManager.clearCalled, true);
    });

    testWidgets('Clear History button shows confirmation dialog and clears messages', (tester) async {
      fakeDb.storedMessages.add(
        AIMessageModel(id: 1, text: 'Tin nhắn cũ cần xóa', isUser: false),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tin nhắn cũ cần xóa'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('xóa toàn bộ lịch sử'), findsOneWidget);

      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      expect(find.text('Tin nhắn cũ cần xóa'), findsNothing);
      expect(fakeDb.storedMessages.isEmpty, true);
    });

    testWidgets('renders cleanly in Light Theme mode with offline banner and disclaimer', (tester) async {
      aiProvider.setOfflineModeForTest(true, reason: 'Quá thời gian phản hồi (> 10s)');
      fakeDb.storedMessages.add(
        AIMessageModel(id: 1, text: 'Phản hồi chế độ sáng', isUser: false, isOffline: true),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIAssistantProvider>.value(value: aiProvider),
            ChangeNotifierProvider<SleepProvider>.value(value: sleepProvider),
          ],
          child: MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: AIAssistantScreen(apiKeyManager: fakeKeyManager),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Không có kết nối Internet'), findsOneWidget);
      expect(find.text('[Ngoại tuyến]'), findsOneWidget);
      expect(find.text('Phản hồi chế độ sáng'), findsOneWidget);
    });
  });
}
