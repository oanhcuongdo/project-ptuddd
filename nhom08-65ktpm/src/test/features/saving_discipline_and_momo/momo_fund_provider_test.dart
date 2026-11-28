import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/models/momo_fund_config.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/momo_fund_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/utils/momo_deeplink_helper.dart';

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
  });
}
