import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/sleep_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'Tôi hay bị khó ngủ, có cách nào thư giãn không?',
    'Nên ngủ trưa bao nhiêu phút là tốt nhất?',
    'Uống cà phê sau mấy giờ thì không ảnh hưởng giấc ngủ?',
    'Hướng dẫn tôi kỹ thuật thở 4-7-8 để dễ ngủ.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIAssistantProvider>().loadMessages();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    final sleepProv = context.read<SleepProvider>();
    final summary = 'Mục tiêu: ${sleepProv.goal.targetDurationHours}h. Tỷ lệ tuân thủ gần đây: ${sleepProv.complianceRate.round()}%.';

    context.read<AIAssistantProvider>().sendMessage(text, sleepSummary: summary);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AIAssistantProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Sleep Assistant'),
      ),
      body: Column(
        children: [
          // 1. Quick suggestion chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedPrompts.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    backgroundColor: AppTheme.surfaceNavy,
                    label: Text(_suggestedPrompts[i], style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan)),
                    onPressed: () => _handleSend(_suggestedPrompts[i]),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // 2. Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: aiProv.messages.length,
              itemBuilder: (context, index) {
                final msg = aiProv.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (aiProv.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Trợ lý AI đang suy nghĩ câu trả lời...', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),

          // 3. Text Input Box
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.surfaceNavy,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi về giấc ngủ...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: AppTheme.primaryNavy,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.accentIndigo,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: () => _handleSend(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.accentIndigo : AppTheme.surfaceNavy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 14,
            color: isUser ? Colors.white : AppTheme.textLight,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
