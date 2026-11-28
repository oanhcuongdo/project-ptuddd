import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/ai_message_model.dart';
import '../../data/services/api_key_manager.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/sleep_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  final ApiKeyManager? apiKeyManager;

  const AIAssistantScreen({super.key, this.apiKeyManager});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final ApiKeyManager _apiKeyManager;

  final List<String> _suggestedPrompts = const [
    'Tôi hay bị khó ngủ, có cách nào thư giãn không?',
    'Nên ngủ trưa bao nhiêu phút là tốt nhất?',
    'Uống cà phê sau mấy giờ thì không ảnh hưởng giấc ngủ?',
    'Hướng dẫn tôi kỹ thuật thở 4-7-8 để dễ ngủ.',
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyManager = widget.apiKeyManager ?? ApiKeyManager();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AIAssistantProvider>().loadMessages();
      if (mounted) _scrollToBottom();
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

  Future<void> _handleSend([String? presetText]) async {
    final aiProv = context.read<AIAssistantProvider>();
    if (aiProv.isThinking) return;

    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty) return;

    final sleepProv = context.read<SleepProvider>();
    final goalHours = sleepProv.goal.targetDurationHours;
    final compliance = sleepProv.complianceRate.round();
    final avgHours = sleepProv.averageDurationHours.toStringAsFixed(1);
    final latest = sleepProv.latestRecord;
    final latestPart = latest != null
        ? ' Đêm gần nhất: ${latest.durationHours.toStringAsFixed(1)}h (cảm nhận ${latest.feelingRating}/5).'
        : '';
    final summary =
        'Mục tiêu: ${goalHours}h. Tỷ lệ tuân thủ 7 ngày: $compliance%. Thời lượng ngủ TB: ${avgHours}h.$latestPart';

    if (presetText == null) {
      _textController.clear();
    }
    _scrollToBottom();
    await aiProv.sendMessage(text, sleepSummary: summary);
    if (mounted) {
      _scrollToBottom();
    }
  }

  Future<void> _showApiKeyDialog() async {
    final hasCustom = await _apiKeyManager.hasCustomApiKey();
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ApiKeyConfigDialog(
        apiKeyManager: _apiKeyManager,
        hasCustomKey: hasCustom,
      ),
    );

    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: AppTheme.softGreen,
      ),
    );
  }

  Future<void> _showClearHistoryDialog(AIAssistantProvider aiProv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử trò chuyện'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện với Trợ lý AI không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.softRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await aiProv.clearHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ lịch sử trò chuyện.')),
      );
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final surfaceColor =
        isDark ? AppTheme.surfaceNavy : colorScheme.surfaceContainerHighest;
    final inputFillColor =
        isDark ? AppTheme.primaryNavy : colorScheme.surface;
    final chipTextColor =
        isDark ? AppTheme.accentCyan : colorScheme.primary;
    final offlineBannerTextColor =
        isDark ? Colors.amber.shade200 : Colors.amber.shade900;
    final disclaimerColor =
        isDark ? AppTheme.textMuted : colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Sleep Assistant'),
        actions: [
          Semantics(
            label: 'Cấu hình Gemini API Key',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.vpn_key_outlined),
              tooltip: 'Cấu hình Gemini API Key',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: _showApiKeyDialog,
            ),
          ),
          Semantics(
            label: 'Xóa lịch sử trò chuyện',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa lịch sử trò chuyện',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed:
                  aiProv.isThinking ? null : () => _showClearHistoryDialog(aiProv),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Banner chế độ ngoại tuyến (hiện tức thì khi mất mạng)
          if (aiProv.isOfflineMode)
            Container(
              width: double.infinity,
              color: Colors.amber.shade900.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 16,
                    color: offlineBannerTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không có kết nối Internet — Đang hoạt động ở chế độ ngoại tuyến (Tri thức cục bộ)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: offlineBannerTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Banner lỗi dịch vụ AI (chỉ hiện khi có mạng nhưng API lỗi)
          if (!aiProv.isOfflineMode && aiProv.apiError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade900.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiProv.apiError!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: aiProv.clearApiError,
                  ),
                ],
              ),
            ),

          // 2. Thanh gợi ý nhanh (Quick Chips)
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return ActionChip(
                  backgroundColor: surfaceColor,
                  side: BorderSide(
                    color: chipTextColor.withValues(alpha: 0.35),
                  ),
                  label: Text(
                    _suggestedPrompts[i],
                    style: TextStyle(fontSize: 12, color: chipTextColor),
                  ),
                  onPressed: aiProv.isThinking
                      ? null
                      : () => _handleSend(_suggestedPrompts[i]),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // 3. Danh sách tin nhắn hội thoại
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: aiProv.messages.length,
              itemBuilder: (context, index) {
                final msg = aiProv.messages[index];
                return _buildMessageBubble(msg, isDark, colorScheme);
              },
            ),
          ),

          // 4. Chỉ báo trạng thái đang phân tích
          if (aiProv.isThinking)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Đang phân tích thói quen...',
                    style: TextStyle(fontSize: 12, color: disclaimerColor),
                  ),
                ],
              ),
            ),

          // 5. Thanh nhập liệu + Khuyến cáo y tế cố định chân trang
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Nhập câu hỏi về giấc ngủ...',
                            hintStyle: TextStyle(
                              color: disclaimerColor,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: inputFillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label: 'Gửi câu hỏi',
                        button: true,
                        child: IconButton(
                          tooltip: 'Gửi câu hỏi',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.accentIndigo,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppTheme.accentIndigo.withValues(alpha: 0.4),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 20),
                          onPressed:
                              aiProv.isThinking ? null : () => _handleSend(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        size: 13,
                        color: disclaimerColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'DCSleep AI cung cấp kiến thức vệ sinh giấc ngủ nhằm xây dựng thói quen khoa học, không thay thế chẩn đoán y tế.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: disclaimerColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    AIMessageModel msg,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final isUser = msg.isUser;
    final botBgColor =
        isDark ? AppTheme.surfaceNavy : colorScheme.surfaceContainerHighest;
    final botTextColor = isDark ? AppTheme.textLight : colorScheme.onSurface;
    final tagBgColor = isDark
        ? AppTheme.cardNavy
        : colorScheme.secondaryContainer;
    final tagTextColor = isDark
        ? AppTheme.textMuted
        : colorScheme.onSecondaryContainer;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.accentIndigo : botBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser && msg.isOffline)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 12, color: tagTextColor),
                    const SizedBox(width: 4),
                    Text(
                      '[Ngoại tuyến]',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tagTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : botTextColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyConfigDialog extends StatefulWidget {
  final ApiKeyManager apiKeyManager;
  final bool hasCustomKey;

  const _ApiKeyConfigDialog({
    required this.apiKeyManager,
    required this.hasCustomKey,
  });

  @override
  State<_ApiKeyConfigDialog> createState() => _ApiKeyConfigDialogState();
}

class _ApiKeyConfigDialogState extends State<_ApiKeyConfigDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập hoặc dán API Key');
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    await widget.apiKeyManager.saveCustomApiKey(key);
    if (!mounted) return;
    Navigator.pop(context, 'Đã lưu Gemini API Key an toàn.');
  }

  Future<void> _onClear() async {
    setState(() => _saving = true);
    await widget.apiKeyManager.clearCustomApiKey();
    if (!mounted) return;
    Navigator.pop(context, 'Đã xóa API Key tùy chỉnh.');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cấu hình Gemini API Key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hasCustomKey
                ? 'Trạng thái: Đang dùng khóa tùy chỉnh đã lưu an toàn.'
                : 'Trạng thái: Chưa lưu khóa tùy chỉnh (dùng khóa mặc định khi build nếu có).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Gemini API Key',
              hintText: 'Dán khóa API (AIza... hoặc AQ...)',
              errorText: _errorText,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Hiện khóa' : 'Ẩn khóa',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        if (widget.hasCustomKey)
          TextButton(
            onPressed: _saving ? null : _onClear,
            style: TextButton.styleFrom(foregroundColor: AppTheme.softRed),
            child: const Text('Xóa key'),
          ),
        ElevatedButton(
          onPressed: _saving ? null : _onSave,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
