import 'package:flutter/material.dart';
import '../data/database/database_helper.dart';
import '../data/models/ai_message_model.dart';
import '../data/services/gemini_ai_service.dart';

class AIAssistantProvider extends ChangeNotifier {
  List<AIMessageModel> _messages = [];
  bool _isLoading = false;

  List<AIMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> loadMessages() async {
    _messages = await DatabaseHelper.instance.getAIMessages();
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? sleepSummary}) async {
    if (text.trim().isEmpty) return;

    // 1. Add User Message
    final userMsg = AIMessageModel(text: text.trim(), isUser: true);
    await DatabaseHelper.instance.insertAIMessage(userMsg);
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    // 2. Query Gemini / Local Knowledge Base
    final responseText = await GeminiAIService.instance.askSleepAssistant(
      text,
      sleepSummaryContext: sleepSummary,
    );

    // 3. Add AI Message
    final aiMsg = AIMessageModel(text: responseText, isUser: false);
    await DatabaseHelper.instance.insertAIMessage(aiMsg);
    _messages.add(aiMsg);

    _isLoading = false;
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}

