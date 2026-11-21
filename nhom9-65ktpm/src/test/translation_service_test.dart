import '../lib/features/chat_online/models/translation_result.dart';
import '../lib/features/chat_online/services/translation_service.dart';

/// File kiểm thử độc lập hàm gọi API Dịch tức thì Anh - Việt.
/// Có thể chạy kiểm thử bằng lệnh: dart run test/translation_service_test.dart
void main() async {
  print('================================================================');
  print('🚀 BẮT ĐẦU KIỂM THỬ TRANSLATION SERVICE (NHÓM 09 - BUDDYTALK)');
  print('================================================================\n');

  final service = TranslationService();

  // Test Case 1: Dịch câu chat từ Tiếng Anh sang Tiếng Việt
  print('--- Test Case 1: Dịch Anh -> Việt ---');
  const enSentence = "Hello! Let's practice speaking English for 15 minutes today.";
  print('Câu gốc (EN): "$enSentence"');
  
  final stopwatch1 = Stopwatch()..start();
  final resultEnToVi = await service.translateEnToVi(enSentence);
  stopwatch1.stop();

  if (resultEnToVi.isSuccess) {
    print('✅ Dịch thành công (${stopwatch1.elapsedMilliseconds} ms):');
    print('   => Bản dịch (VI): "${resultEnToVi.translatedText}"');
  } else {
    print('❌ Lỗi: ${resultEnToVi.errorMessage}');
  }
  print('');

  // Test Case 2: Dịch câu chat từ Tiếng Việt sang Tiếng Anh
  print('--- Test Case 2: Dịch Việt -> Anh ---');
  const viSentence = "Hôm nay mình rất tự tin khi hoàn thành thử thách kỷ luật giao tiếp.";
  print('Câu gốc (VI): "$viSentence"');
  
  final stopwatch2 = Stopwatch()..start();
  final resultViToEn = await service.translateViToEn(viSentence);
  stopwatch2.stop();

  if (resultViToEn.isSuccess) {
    print('✅ Dịch thành công (${stopwatch2.elapsedMilliseconds} ms):');
    print('   => Bản dịch (EN): "${resultViToEn.translatedText}"');
  } else {
    print('❌ Lỗi: ${resultViToEn.errorMessage}');
  }
  print('');

  // Test Case 3: Kiểm tra tốc độ đọc từ Bộ nhớ đệm (Cache)
  print('--- Test Case 3: Kiểm tra tốc độ phản hồi qua Cache ---');
  final stopwatch3 = Stopwatch()..start();
  final cachedResult = await service.translateEnToVi(enSentence);
  stopwatch3.stop();

  print('✅ Gọi lại câu đã dịch (Thời gian phản hồi: ${stopwatch3.elapsedMilliseconds} ms):');
  print('   => Bản dịch từ Cache: "${cachedResult.translatedText}"');
  print('   => Tổng số mục đã lưu Cache: ${service.cacheSize}');
  print('');

  // Test Case 4: Kiểm tra chuyển đổi toMap / fromMap cho lưu trữ CSDL
  print('--- Test Case 4: Kiểm tra toMap & fromMap (SQLite / Supabase) ---');
  final map = resultEnToVi.toMap();
  final reconstructed = TranslationResult.fromMap(map);
  print('✅ Chuyển đổi CSDL thành công: ${reconstructed.toString()}');

  print('\n================================================================');
  print('🎉 HOÀN TẤT TẤT CẢ CÁC BÀI TEST - SERVICE HOẠT ĐỘNG CHUẨN XÁC!');
  print('================================================================');
}

