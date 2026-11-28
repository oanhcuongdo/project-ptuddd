import 'package:dcsleep/data/models/ai_message_model.dart';

/// Ngoại lệ chuyên biệt cho tầng dịch vụ AI trực tuyến.
/// Giúp AIAssistantProvider phân loại lỗi mạng/API và kích hoạt dự phòng ngoại tuyến.
class AIServiceException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  AIServiceException(this.message, {this.statusCode, this.cause});

  @override
  String toString() => 'AIServiceException: $message (code: $statusCode)';
}

/// Interface chung cho các nhà cung cấp mô hình AI (Strategy Pattern).
abstract class AIService {
  Future<String> askAssistant({
    required String prompt,
    String? sleepContext,
    List<AIMessageModel> history = const [],
  });

  void setApiKey(String key);

  bool get hasApiKey;
}
