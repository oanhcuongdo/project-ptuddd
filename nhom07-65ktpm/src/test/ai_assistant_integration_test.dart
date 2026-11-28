import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dcsleep/core/theme/app_theme.dart';
import 'package:dcsleep/data/database/database_helper.dart';
import 'package:dcsleep/data/services/api_key_manager.dart';
import 'package:dcsleep/data/services/gemini_ai_service.dart';
import 'package:dcsleep/providers/ai_assistant_provider.dart';
import 'package:dcsleep/providers/sleep_provider.dart';
import 'package:dcsleep/screens/ai_assistant/ai_assistant_screen.dart';

Future<void> _flushRealAsyncAndPump(
  WidgetTester tester,
  AIAssistantProvider provider,
) async {
  for (int i = 0; i < 40; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump();
    if (!provider.isThinking) break;
  }
  await tester.pump(); // run addPostFrameCallback -> animateTo
  await tester.pump(const Duration(milliseconds: 400)); // complete scroll animation
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeDatabase();
  });

  group('AI Sleep Assistant End-to-End Acceptance Criteria (1-8)', () {
    testWidgets(
      'E2E Flow: UI launch, Gemini 2.5 Flash multi-turn, SafetyGuardrails, Offline fallback, Auto-recovery, SQLite persistence & Clear History',
      (tester) async {
        final apiKeyManager = ApiKeyManager();
        await tester.runAsync(
          () => apiKeyManager.saveCustomApiKey('AQ.E2ETestSecretKey'),
        );

        bool simulateNetworkOutage = false;
        final capturedRequests = <Map<String, dynamic>>[];

        final mockHttpClient = MockClient((request) async {
          expect(
            request.url.toString(),
            contains('gemini-3.5-flash-lite:generateContent'),
          );
          expect(request.url.queryParameters.containsKey('key'), false);
          expect(request.headers['x-goog-api-key'], 'AQ.E2ETestSecretKey');

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          capturedRequests.add(body);

          if (simulateNetworkOutage) {
            throw const SocketException('Network unreachable');
          }

          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text':
                            'Phản hồi Gemini turn ${capturedRequests.length}: Hãy giữ phòng mát 20-24°C và ngủ đúng giờ.',
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final aiService = GeminiAIService(client: mockHttpClient);
        final aiProvider = AIAssistantProvider(
          databaseHelper: DatabaseHelper.instance,
          aiService: aiService,
          apiKeyManager: apiKeyManager,
          enableNetworkListener: false,
        );
        final sleepProvider = SleepProvider();
        await tester.runAsync(sleepProvider.loadData);

        Widget buildApp(AIAssistantProvider activeProvider) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<AIAssistantProvider>.value(
                value: activeProvider,
              ),
              ChangeNotifierProvider<SleepProvider>.value(value: sleepProvider),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: AIAssistantScreen(apiKeyManager: apiKeyManager),
            ),
          );
        }

        // Tiêu chí 1: Khởi chạy giao diện mượt mà, hiển thị disclaimer & tin nhắn chào từ SQLite
        await tester.pumpWidget(buildApp(aiProvider));
        await _flushRealAsyncAndPump(tester, aiProvider);

        expect(find.text('AI Sleep Assistant'), findsOneWidget);
        expect(
          find.textContaining('không thay thế chẩn đoán y tế'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Trợ lý AI Giấc ngủ DCSleep'),
          findsOneWidget,
        );

        // Tiêu chí 2 & 3: Gửi câu hỏi Online lần 1 qua giao diện
        await tester.enterText(
          find.byType(TextField).first,
          'Làm sao ngủ ngon hơn?',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _flushRealAsyncAndPump(tester, aiProvider);

        expect(aiProvider.offlineReason, isNull);
        expect(aiProvider.isThinking, false);
        expect(capturedRequests.length, 1);
        final turn1Payload = capturedRequests[0];
        expect(turn1Payload['generationConfig']['maxOutputTokens'], 1024);
        expect(turn1Payload['generationConfig'].containsKey('thinkingConfig'), false);

        final sysInstruction =
            turn1Payload['systemInstruction']['parts'][0]['text'] as String;
        expect(
          sysInstruction,
          contains('[DỮ LIỆU THỰC TẾ TỪ DCSLEEP HIỆN TẠI]'),
        );
        expect(sysInstruction, contains('8.0h'));

        expect(find.text('Làm sao ngủ ngon hơn?'), findsOneWidget);
        expect(find.textContaining('Phản hồi Gemini turn 1'), findsOneWidget);

        // Đảm bảo dữ liệu tiêm hệ thống KHÔNG lưu vào bảng SQLite
        final dbMessagesAfterTurn1 = await tester.runAsync(
          DatabaseHelper.instance.getAllAIMessages,
        );
        expect(
          dbMessagesAfterTurn1!.any((m) => m.text.contains('[DỮ LIỆU THỰC TẾ')),
          false,
        );

        // Tiêu chí 4: Hỏi nối tiếp đa lượt (kiểm tra xen kẽ user -> model -> user)
        await tester.enterText(
          find.byType(TextField).first,
          'Nhiệt độ phòng thế nào là chuẩn?',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _flushRealAsyncAndPump(tester, aiProvider);

        expect(capturedRequests.length, 2);
        final turn2Contents = capturedRequests[1]['contents'] as List<dynamic>;
        expect(turn2Contents.first['role'], 'user');
        expect(turn2Contents.last['role'], 'user');
        for (int i = 0; i < turn2Contents.length - 1; i++) {
          expect(
            turn2Contents[i]['role'],
            isNot(equals(turn2Contents[i + 1]['role'])),
          );
        }

        // Tiêu chí 6: An toàn 2 lớp (tiếng Việt không dấu "thuoc ngu")
        await tester.enterText(
          find.byType(TextField).first,
          'Toi muon mua thuoc ngu',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _flushRealAsyncAndPump(tester, aiProvider);

        expect(capturedRequests.length, 2); // Không gọi API
        expect(aiProvider.isOfflineMode, false);
        expect(find.byIcon(Icons.wifi_off), findsNothing);
        expect(
          find.textContaining('CẢNH BÁO Y TẾ'),
          findsOneWidget,
        );

        // Tiêu chí 5a: Mất mạng -> Chuyển sang OfflineSleepEngine + Banner + Tag [Ngoại tuyến]
        simulateNetworkOutage = true;
        await tester.enterText(
          find.byType(TextField).first,
          'Ngủ trưa bao nhiêu phút?',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _flushRealAsyncAndPump(tester, aiProvider);

        expect(aiProvider.isOfflineMode, true);
        expect(
          find.textContaining('Không có kết nối Internet'),
          findsOneWidget,
        );
        expect(find.text('[Ngoại tuyến]'), findsOneWidget);
        expect(find.textContaining('Power Nap'), findsOneWidget);

        // Nhánh Default Fallback khi câu hỏi ngoài chủ đề
        await tester.enterText(
          find.byType(TextField).first,
          'Chứng khoán hôm nay tăng không?',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _flushRealAsyncAndPump(tester, aiProvider);

        expect(
          find.textContaining('chế độ ngoại tuyến'),
          findsAtLeastNWidgets(1),
        );

        // Tiêu chí 7a: Mô phỏng đóng hẳn và mở lại app -> SQLite khôi phục chính xác tag [Ngoại tuyến]
        final restartedProvider = AIAssistantProvider(
          databaseHelper: DatabaseHelper.instance,
          aiService: aiService,
          apiKeyManager: apiKeyManager,
          enableNetworkListener: false,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(buildApp(restartedProvider));
        await _flushRealAsyncAndPump(tester, restartedProvider);

        expect(restartedProvider.messages.where((m) => m.isOffline).length, 2);
        expect(find.text('[Ngoại tuyến]'), findsAtLeastNWidgets(1));

        // Tiêu chí 5b: Đang mất mạng ở phiên mới -> Có mạng lại -> Tự phục hồi Online và ẩn Banner ngoại tuyến
        await tester.enterText(
          find.byType(TextField).first,
          'Ngủ bao lâu mỗi ngày?',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _flushRealAsyncAndPump(tester, restartedProvider);

        expect(restartedProvider.isOfflineMode, true);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);

        simulateNetworkOutage = false;

        await tester.enterText(
          find.byType(TextField).first,
          'Mạng đã ổn chưa?',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _flushRealAsyncAndPump(tester, restartedProvider);

        expect(restartedProvider.isOfflineMode, false);
        expect(restartedProvider.offlineReason, isNull);
        expect(find.byIcon(Icons.wifi_off), findsNothing);

        // Tiêu chí 7b: Xóa lịch sử qua Dialog xác nhận làm sạch hoàn toàn SQLite
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.text('Xóa'));
        await _flushRealAsyncAndPump(tester, restartedProvider);

        final remainingMessages = await tester.runAsync(
          DatabaseHelper.instance.getAllAIMessages,
        );
        expect(remainingMessages!.isEmpty, true);
        expect(find.text('Mạng đã ổn chưa?'), findsNothing);
      },
    );

    test(
      'SQLite v1 -> v2 migration preserves existing chat rows and sets default is_offline = 0',
      () async {
        await DatabaseHelper.instance.closeDatabase();

        final v1Db = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE ai_conversations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                text TEXT NOT NULL,
                is_user INTEGER NOT NULL,
                timestamp TEXT NOT NULL
              )
            ''');
            await db.insert('ai_conversations', {
              'text': 'Tin nhắn từ bản build v1 cũ',
              'is_user': 0,
              'timestamp': '2026-11-20T08:00:00',
            });
          },
        );

        await DatabaseHelper.instance.onUpgrade(v1Db, 1, 2);
        final rows = await v1Db.query('ai_conversations');
        expect(rows.length, 1);
        expect(rows.first['text'], 'Tin nhắn từ bản build v1 cũ');
        expect(rows.first['is_offline'], 0);
        await v1Db.close();
      },
    );
  });
}
