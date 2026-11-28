import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/models/momo_fund_config.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/deposit_receipt_sheet.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/screens/momo_qr_scanner_screen.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/momo_fund_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/utils/momo_deeplink_helper.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/utils/momo_launcher.dart';

class _FailingSavingRepository extends InMemorySavingRepository {
  @override
  Future<void> saveFundConfig(MoMoFundConfig config) async {
    throw Exception('Firestore write failed');
  }
}

void main() {
  group('MoMoFundProvider Tests', () {
    test('saveFundConfig persists config and emits on momoFundStreamProvider', () async {
      final repo = InMemorySavingRepository();
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const tripId = 'trip_test_01';
      final sub = container.listen(momoFundStreamProvider(tripId), (_, _) {});
      addTearDown(sub.close);

      final saved = await container.read(momoFundProvider(tripId).notifier).saveFundConfig(
            fundName: 'Quỹ Đà Lạt Nhóm 8',
            hostUserId: 'host_1',
            hostName: 'Bình',
            momoPhoneNumber: '0912345678',
            momoFundDeeplink: 'https://me.momo.vn/quy-nhom-dl-g8',
            targetTotalAmount: 8450000,
          );

      expect(saved.fundName, 'Quỹ Đà Lạt Nhóm 8');
      expect(saved.momoPhoneNumber, '0912345678');

      final fetched = await repo.getFundConfig(tripId);
      expect(fetched, isNotNull);
      expect(fetched!.fundName, 'Quỹ Đà Lạt Nhóm 8');
      expect(fetched.momoFundDeeplink, 'https://me.momo.vn/quy-nhom-dl-g8');
    });

    test('saveFundConfig rethrows error when repository fails', () async {
      final container = ProviderContainer(
        overrides: [
          savingRepositoryProvider.overrideWithValue(_FailingSavingRepository()),
        ],
      );
      addTearDown(container.dispose);

      const tripId = 'trip_test_fail';
      await expectLater(
        container.read(momoFundProvider(tripId).notifier).saveFundConfig(
              fundName: 'Quỹ Lỗi',
              hostUserId: 'host_1',
              hostName: 'Bình',
              momoPhoneNumber: '0912345678',
              targetTotalAmount: 1000000,
            ),
        throwsException,
      );

      expect(container.read(momoFundProvider(tripId)).hasError, isTrue);
    });

    test('saveFundConfig succeeds even when momoFundProvider has no active watch', () async {
      final repo = InMemorySavingRepository();
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const tripId = 'trip_unwatched_01';
      final saved = await container.read(momoFundProvider(tripId).notifier).saveFundConfig(
            fundName: 'Quỹ Không Watch',
            hostUserId: 'host_1',
            hostName: 'Bình',
            momoPhoneNumber: '0912345678',
            targetTotalAmount: 5000000,
          );

      expect(saved.fundName, 'Quỹ Không Watch');
      final fetched = await repo.getFundConfig(tripId);
      expect(fetched?.fundName, 'Quỹ Không Watch');
    });
  });

  group('MoMoDeeplinkHelper QR Parsing Tests', () {
    test('parses MoMo pipe-delimited transfer QR payload', () {
      final parsed = MoMoDeeplinkHelper.parseMoMoQr(
        '2|99|0912345678|Nguyen Xuan Binh|test@mail.com|0|0|0||transfer_myqr',
      );
      expect(parsed.phoneNumber, '0912345678');
      expect(parsed.recipientName, 'Nguyen Xuan Binh');
      expect(parsed.deeplink, 'https://nhantien.momo.vn/0912345678');
    });

    test('parses MoMo URL with embedded phone number', () {
      final parsed = MoMoDeeplinkHelper.parseMoMoQr(
        'https://nhantien.momo.vn/0987654321',
      );
      expect(parsed.phoneNumber, '0987654321');
      expect(parsed.deeplink, 'https://nhantien.momo.vn/0987654321');
    });

    test('parses EMVCo VietQR payload with merchant name and phone', () {
      const vietQr =
          '00020101021138540010A00000072701240006970454011009123456780208QRIBFTTA53037045802VN5911NGUYEN BINH6304ABCD';
      final parsed = MoMoDeeplinkHelper.parseMoMoQr(vietQr);
      expect(parsed.phoneNumber, '0912345678');
      expect(parsed.recipientName, 'NGUYEN BINH');
      expect(parsed.deeplink, 'https://nhantien.momo.vn/0912345678');
    });

    test('ThousandsDotInputFormatter formats digits with dots and preserves cursor', () {
      final formatter = ThousandsDotInputFormatter();
      final res1 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1500000',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      expect(res1.text, '1.500.000');
      expect(res1.selection.baseOffset, 9);

      // Typing a digit after '15' -> cursor stays right after that digit ('15.200.000' -> offset 3)
      final res2 = formatter.formatEditUpdate(
        res1,
        const TextEditingValue(
          text: '1.5200.000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(res2.text, '15.200.000');
      expect(res2.selection.baseOffset, 4);
    });

    test('handles malformed VietQR, truncated pipe QR, and invalid links safely without throwing', () {
      final truncatedEmv = MoMoDeeplinkHelper.parseMoMoQr('0002013899invalid');
      expect(truncatedEmv.rawPayload, '0002013899invalid');
      expect(truncatedEmv.phoneNumber, isNull);
      expect(truncatedEmv.deeplink, isNull);

      final malformedUrl = MoMoDeeplinkHelper.parseMoMoQr('https://');
      expect(malformedUrl.phoneNumber, isNull);
      expect(malformedUrl.deeplink, isNull);

      final garbage = MoMoDeeplinkHelper.parseMoMoQr('2|99|notaphone');
      expect(garbage.rawPayload, '2|99|notaphone');
      expect(garbage.phoneNumber, isNull);
    });

    testWidgets('MoMoLauncher verifies canLaunchUrl and triggers clipboard fallback when unavailable', (tester) async {
      final calls = <String>[];
      String? copiedText;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          calls.add(call.method);
          if (call.method == 'canLaunch') return false;
          return false;
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      bool? launched;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  launched = await MoMoLauncher.openMoMo(
                    context,
                    deeplink: 'https://me.momo.vn/test-fund',
                    copySummary: '0912345678 - TravelBuddy',
                  );
                },
                child: const Text('Launch MoMo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch MoMo'));
      await tester.pumpAndSettle();

      expect(launched, isFalse);
      expect(copiedText, '0912345678 - TravelBuddy');
      expect(calls, contains('canLaunch'));
      expect(calls, isNot(contains('launch')));
      expect(
        find.textContaining('Không tìm thấy ứng dụng MoMo trên thiết bị'),
        findsOneWidget,
      );
    });

    testWidgets('MomoQrScannerScreen does not re-request permission on resume after denial and supports Settings check', (tester) async {
      var requestCount = 0;
      var statusCheckCount = 0;
      var currentStatus = 0; // 0 = denied, 4 = permanentlyDenied, 1 = granted

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
              statusCheckCount += 1;
              return currentStatus;
            case 'requestPermissions':
              requestCount += 1;
              currentStatus = 4; // Become permanently denied after prompt
              final list = call.arguments as List;
              return {for (final p in list) p: currentStatus};
            case 'openAppSettings':
              return true;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          null,
        );
      });

      await tester.pumpWidget(
        const MaterialApp(home: MomoQrScannerScreen()),
      );
      await tester.pumpAndSettle();

      expect(requestCount, 1);
      expect(find.text('Mở Cài đặt'), findsOneWidget);
      expect(find.text('Đã cấp quyền? Kiểm tra lại'), findsOneWidget);

      // Resuming while still denied must NOT re-trigger requestPermissions (no blink loop).
      final checksBeforeResume = statusCheckCount;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(requestCount, 1);
      expect(statusCheckCount, greaterThan(checksBeforeResume));

      // Tapping manual re-check while still denied gives clear snackbar feedback.
      await tester.tap(find.text('Đã cấp quyền? Kiểm tra lại'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Quyền camera vẫn chưa được bật'),
        findsOneWidget,
      );
    });

    testWidgets(
        'DepositReceiptSheet requests camera permission natively and shows inline Settings button on permanent denial',
        (tester) async {
      var openSettingsCount = 0;
      var requestCount = 0;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
              return 0; // denied -> allows native request()
            case 'requestPermissions':
              requestCount += 1;
              final list = call.arguments as List;
              return {for (final p in list) p: 4}; // permanentlyDenied
            case 'openAppSettings':
              openSettingsCount += 1;
              return true;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          null,
        );
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DepositReceiptSheet(fundName: 'Quỹ test'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.text('Chụp / Tải ảnh biên lai giao dịch MoMo'),
      );
      await tester.tap(find.text('Chụp / Tải ảnh biên lai giao dịch MoMo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chụp ảnh biên lai mới'));
      await tester.pumpAndSettle();

      expect(requestCount, 1);
      expect(
        find.textContaining('Quyền camera đã bị từ chối vĩnh viễn'),
        findsOneWidget,
      );
      expect(find.text('Mở Cài đặt'), findsOneWidget);

      await tester.tap(find.text('Mở Cài đặt'));
      await tester.pump();
      expect(openSettingsCount, 1);
    });
  });
}
