import 'package:flutter_test/flutter_test.dart';
import 'package:dcsleep/data/services/offline_sleep_engine.dart';

void main() {
  group('OfflineSleepEngine Comprehensive Tests', () {
    const medicalDisclaimer = 'không thay thế chỉ định y tế';

    test('OfflineSleepEngine supports exactly 8 topics', () {
      expect(OfflineSleepEngine.supportedTopicCount, 8);
    });

    group('4 Core Topics (Accents, Non-accents, Uppercase, Punctuation)', () {
      test('Power Nap: handles varied formats', () {
        final ans1 = OfflineSleepEngine.getAdvice('Ngủ trưa bao nhiêu phút?');
        expect(ans1.contains('Power Nap'), true);
        expect(ans1.contains('10 – 20 phút') || ans1.contains('10 - 20 phút') || ans1.contains('15 – 20 phút') || ans1.contains('15 - 20 phút'), true);
        expect(ans1.contains('Sleep Inertia'), true);
        expect(ans1.toLowerCase().contains(medicalDisclaimer), true);

        final ans2 = OfflineSleepEngine.getAdvice('NGU TRUA 45 phut??');
        expect(ans2.contains('Power Nap'), true);
        expect(ans2.contains('Sleep Inertia'), true);
        expect(ans2.toLowerCase().contains(medicalDisclaimer), true);
      });

      test('4-7-8 Breathing & Progressive Muscle Relaxation (PMR)', () {
        final ans1 = OfflineSleepEngine.getAdvice('kỹ thuật thở 4-7-8 giãn cơ');
        expect(ans1.contains('4 giây'), true);
        expect(ans1.contains('7 giây'), true);
        expect(ans1.contains('8 giây'), true);
        expect(ans1.contains('phó giao cảm'), true);
        expect(ans1.toLowerCase().contains(medicalDisclaimer), true);

        final ans2 = OfflineSleepEngine.getAdvice('Huong dan tho 478');
        expect(ans2.contains('4 giây'), true);
        expect(ans2.contains('7 giây'), true);
        expect(ans2.contains('8 giây'), true);
        expect(ans2.toLowerCase().contains(medicalDisclaimer), true);
      });

      test('Caffeine & Nutrition Hygiene', () {
        final ans1 = OfflineSleepEngine.getAdvice('Chiều uống cà phê sau mấy giờ?');
        expect(ans1.contains('5 – 7') || ans1.contains('5 - 7') || ans1.contains('5-7'), true);
        expect(ans1.contains('14:00'), true);
        expect(ans1.contains('2 tiếng'), true);
        expect(ans1.toLowerCase().contains(medicalDisclaimer), true);

        final ans2 = OfflineSleepEngine.getAdvice('uong tra sua buoi toi');
        expect(ans2.contains('14:00') || ans2.contains('Caffeine') || ans2.contains('caffeine'), true);
        expect(ans2.toLowerCase().contains(medicalDisclaimer), true);
      });

      test('Difficulty Sleeping / 20-Minute Rule', () {
        final ans1 = OfflineSleepEngine.getAdvice('Nằm trằn trọc mãi không ngủ được');
        expect(ans1.contains('20 phút'), true);
        expect(ans1.contains('đèn vàng'), true);
        expect(ans1.toLowerCase().contains(medicalDisclaimer), true);

        final ans2 = OfflineSleepEngine.getAdvice('tran troc luc nua dem');
        expect(ans2.contains('20 phút'), true);
        expect(ans2.toLowerCase().contains(medicalDisclaimer), true);
      });
    });

    group('4 Extended Sleep Hygiene Topics', () {
      test('Blue Light & Electronic Devices', () {
        final ans = OfflineSleepEngine.getAdvice('Lướt điện thoại trước khi ngủ');
        expect(ans.contains('Melatonin'), true);
        expect(ans.contains('30'), true);
        expect(ans.toLowerCase().contains(medicalDisclaimer), true);
      });

      test('90-Minute Sleep Cycle & Circadian Rhythm', () {
        final ans = OfflineSleepEngine.getAdvice('Chu kỳ giấc ngủ 90 phút và ngủ bù cuối tuần');
        expect(ans.contains('90 phút'), true);
        expect(ans.contains('Social Jetlag'), true);
        expect(ans.toLowerCase().contains(medicalDisclaimer), true);
      });

      test('Stress & Overthinking', () {
        final ans = OfflineSleepEngine.getAdvice('Áp lực deadline bị overthinking khó vào giấc');
        expect(ans.contains('Brain Dump'), true);
        expect(ans.toLowerCase().contains(medicalDisclaimer), true);
      });

      test('Bedroom Environment & Sleep Progress with sleepContext', () {
        final ans1 = OfflineSleepEngine.getAdvice('Phòng ngủ bao nhiêu độ?');
        expect(ans1.contains('20 – 24°C') || ans1.contains('20 - 24°C') || ans1.contains('20-24°C'), true);
        expect(ans1.toLowerCase().contains(medicalDisclaimer), true);

        final ans2 = OfflineSleepEngine.getAdvice(
          'Đánh giá tiến độ giấc ngủ của tôi',
          sleepContext: 'Mục tiêu: 8.0h. Tỷ lệ tuân thủ: 72%.',
        );
        expect(ans2.contains('72%'), true);
        expect(ans2.toLowerCase().contains(medicalDisclaimer), true);
      });
    });

    group('Weighted Keyword Scoring Accuracy (No Misclassification)', () {
      test('Mixed sentence prioritizes difficulty sleeping over dining', () {
        final ans = OfflineSleepEngine.getAdvice('Tôi ăn tối bình thường nhưng nằm trằn trọc không ngủ được');
        expect(ans.contains('20 phút'), true);
        expect(ans.contains('đèn vàng') || ans.contains('rời giường'), true);
      });
    });

    group('Default Fallback & Medical Disclaimer', () {
      test('Unknown queries trigger Default Fallback with Quick Chips guidance', () {
        final ans = OfflineSleepEngine.getAdvice('Hôm nay thời tiết thế nào?');
        expect(ans.contains('chế độ ngoại tuyến'), true);
        expect(ans.contains('4-7-8'), true);
        expect(ans.contains('Quick Chips') || ans.contains('gợi ý'), true);
        expect(ans.toLowerCase().contains(medicalDisclaimer), true);
      });

      test('Empty or whitespace input triggers Default Fallback safely', () {
        final ans = OfflineSleepEngine.getAdvice('   ');
        expect(ans.contains('chế độ ngoại tuyến'), true);
        expect(ans.contains('4-7-8'), true);
        expect(ans.toLowerCase().contains(medicalDisclaimer), true);
      });
    });
  });
}
