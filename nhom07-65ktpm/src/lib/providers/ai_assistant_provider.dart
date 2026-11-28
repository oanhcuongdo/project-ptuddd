import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/ai_message_model.dart';
import '../data/services/ai_service.dart';
import '../data/services/api_key_manager.dart';
import '../data/services/gemini_ai_service.dart';
import '../data/services/offline_sleep_engine.dart';
import '../data/services/safety_guardrails.dart';

/// Quản lý trạng thái hội thoại Trợ lý AI Giấc ngủ (AIAssistantProvider).
/// Tách bạch trạng thái mạng thực (isOfflineMode) và lỗi API (apiError).
/// Lắng nghe connectivity realtime để hiển thị/ẩn banner tức thì.
class AIAssistantProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  final AIService _aiService;
  final ApiKeyManager _apiKeyManager;
  final Connectivity? _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  List<AIMessageModel> _messages = [];
  bool _isThinking = false;
  bool _isOfflineMode = false;
  String? _offlineReason;
  String? _apiError;

  AIAssistantProvider({
    DatabaseHelper? databaseHelper,
    AIService? aiService,
    ApiKeyManager? apiKeyManager,
    Connectivity? connectivity,
    bool enableNetworkListener = true,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _aiService = aiService ?? GeminiAIService.instance,
        _apiKeyManager = apiKeyManager ?? ApiKeyManager(),
        _connectivity = enableNetworkListener ? (connectivity ?? Connectivity()) : null {
    if (_connectivity != null) {
      _initConnectivityListener();
    }
  }

  List<AIMessageModel> get messages => List.unmodifiable(_messages);
  bool get isThinking => _isThinking;
  bool get isLoading => _isThinking; // Alias giữ tương thích ngược
  bool get isOfflineMode => _isOfflineMode;
  String? get offlineReason => _offlineReason;
  String? get apiError => _apiError;

  void clearApiError() {
    if (_apiError != null) {
      _apiError = null;
      notifyListeners();
    }
  }

  Future<void> _initConnectivityListener() async {
    final conn = _connectivity;
    if (conn == null) return;
    try {
      final initial = await conn.checkConnectivity();
      _updateNetworkState(initial);

      _connectivitySub = conn.onConnectivityChanged.listen(
        _updateNetworkState,
      );
    } catch (e) {
      debugPrint('[AIAssistantProvider] Lỗi kết nối Connectivity: $e');
    }
  }

  void _updateNetworkState(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (_isOfflineMode != offline) {
      _isOfflineMode = offline;
      if (offline) {
        _offlineReason = 'Không có kết nối Internet';
      } else {
        _offlineReason = null;
        _apiError = null;
      }
      notifyListeners();
    }
  }

  @visibleForTesting
  void setThinkingForTest(bool value) {
    _isThinking = value;
  }

  @visibleForTesting
  void setOfflineModeForTest(bool value, {String? reason}) {
    _isOfflineMode = value;
    _offlineReason = reason;
  }

  @visibleForTesting
  void setApiErrorForTest(String? error) {
    _apiError = error;
  }

  Future<void> loadMessages() async {
    final loaded = await _databaseHelper.getAllAIMessages();
    _messages = List<AIMessageModel>.from(loaded);
    notifyListeners();
  }

  Future<void> sendMessage(String prompt, {String? sleepSummary}) async {
    final cleanPrompt = prompt.trim();
    if (_isThinking || cleanPrompt.isEmpty) return;

    _isThinking = true;
    _apiError = null;
    notifyListeners();

    try {
      final previousHistory = List<AIMessageModel>.from(_messages);

      final userMsg = AIMessageModel(
        text: cleanPrompt,
        isUser: true,
        isOffline: false,
      );
      await _databaseHelper.insertAIMessage(userMsg);
      _messages.add(userMsg);
      notifyListeners();

      // Tầng 1: SafetyGuardrails cục bộ
      final safetyResult = SafetyGuardrails.evaluate(cleanPrompt);
      if (safetyResult.isBlocked && safetyResult.warningMessage != null) {
        final warningMsg = AIMessageModel(
          text: safetyResult.warningMessage!,
          isUser: false,
          isOffline: false,
        );
        await _databaseHelper.insertAIMessage(warningMsg);
        _messages.add(warningMsg);
        return;
      }

      // Tầng 2: Gọi dịch vụ AI trực tuyến
      try {
        final apiKey = await _apiKeyManager.getApiKey();
        _aiService.setApiKey(apiKey);

        final responseText = await _aiService.askAssistant(
          prompt: cleanPrompt,
          sleepContext: sleepSummary,
          history: previousHistory,
        );

        _isOfflineMode = false;
        _offlineReason = null;
        _apiError = null;

        final aiMsg = AIMessageModel(
          text: responseText,
          isUser: false,
          isOffline: false,
        );
        await _databaseHelper.insertAIMessage(aiMsg);
        _messages.add(aiMsg);
      } catch (e) {
        final isNetworkError = e is SocketException ||
            (e is AIServiceException && e.cause is SocketException);

        if (isNetworkError) {
          _isOfflineMode = true;
          _offlineReason = 'Mất kết nối Internet';
          await _replyOffline(cleanPrompt, sleepSummary);
        } else {
          _apiError = _formatApiError(e);
        }
      }
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  Future<void> _replyOffline(String cleanPrompt, String? sleepSummary) async {
    final offlineReply = OfflineSleepEngine.getAdvice(
      cleanPrompt,
      sleepContext: sleepSummary,
    );
    final offlineMsg = AIMessageModel(
      text: offlineReply,
      isUser: false,
      isOffline: true,
    );
    await _databaseHelper.insertAIMessage(offlineMsg);
    _messages.add(offlineMsg);
  }

  String _formatApiError(Object error) {
    if (error is AIServiceException) {
      if (error.cause is TimeoutException) {
        return 'Máy chủ AI phản hồi quá chậm (> 10s). Vui lòng thử gửi lại.';
      }
      switch (error.statusCode) {
        case null:
          if (error.message.contains('Chưa cấu hình API Key')) {
            return 'Chưa cấu hình Gemini API Key. Hãy bấm biểu tượng chìa khóa để nhập key.';
          }
          return 'Không thể kết nối dịch vụ AI trực tuyến: ${error.message}';
        case 400:
          return 'Yêu cầu gửi lên AI không hợp lệ (HTTP 400).';
        case 401:
        case 403:
          return 'Gemini API Key không hợp lệ hoặc đã bị thu hồi (HTTP ${error.statusCode}).';
        case 404:
          return 'Model AI không tồn tại hoặc đã ngừng hỗ trợ (HTTP 404).';
        case 429:
          return 'Bạn đã vượt quá giới hạn lượt gọi miễn phí (HTTP 429). Vui lòng đợi 1 phút.';
        case 503:
          return 'Máy chủ Gemini đang quá tải tạm thời (HTTP 503). Vui lòng thử lại sau ít giây.';
        default:
          return 'Lỗi dịch vụ AI (HTTP ${error.statusCode}). Vui lòng thử lại.';
      }
    }
    if (error is TimeoutException) {
      return 'Máy chủ AI phản hồi quá chậm. Vui lòng thử lại.';
    }
    return 'Đã xảy ra lỗi không xác định khi kết nối AI.';
  }

  Future<void> clearHistory() async {
    if (_isThinking) return;
    await _databaseHelper.clearAllAIMessages();
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
