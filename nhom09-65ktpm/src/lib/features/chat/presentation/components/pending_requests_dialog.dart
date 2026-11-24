import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/room_join_request.dart';
import '../providers/chat_provider.dart';

/// Hộp thoại dành cho Người quản lý phòng xem và Duyệt / Từ chối yêu cầu xin vào phòng.
class PendingRequestsDialog extends StatefulWidget {
  final ConversationModel room;
  final String currentUserId;

  const PendingRequestsDialog({
    super.key,
    required this.room,
    required this.currentUserId,
  });

  @override
  State<PendingRequestsDialog> createState() => _PendingRequestsDialogState();
}

class _PendingRequestsDialogState extends State<PendingRequestsDialog> {
  List<RoomJoinRequest> _requests = const [];
  bool _isLoading = true;
  String? _busyUserId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await context
          .read<ChatProvider>()
          .fetchPendingRequests(widget.room.id);
      if (!mounted) return;
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải danh sách yêu cầu: $e';
      });
    }
  }

  Future<void> _handleDecision(RoomJoinRequest req, {required bool approve}) async {
    setState(() => _busyUserId = req.userId);
    final chat = context.read<ChatProvider>();
    final ok = approve
        ? await chat.approveJoinRequest(
            conversationId: widget.room.id,
            targetUserId: req.userId,
            currentUserId: widget.currentUserId,
          )
        : await chat.rejectJoinRequest(
            conversationId: widget.room.id,
            targetUserId: req.userId,
            currentUserId: widget.currentUserId,
          );
    if (!mounted) return;
    setState(() {
      _busyUserId = null;
      if (ok) {
        _requests = _requests.where((r) => r.userId != req.userId).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kiểm duyệt thành viên',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.room.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.error))
              else if (_requests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Không có yêu cầu nào đang chờ duyệt.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 16, color: AppColors.divider),
                    itemBuilder: (_, index) {
                      final req = _requests[index];
                      final isBusy = _busyUserId == req.userId;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFEEF2FF),
                            child: Text(
                              req.displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Trình độ: ${req.proficiencyLevel}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () => _handleDecision(req, approve: false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.4),
                              ),
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Từ chối'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: isBusy
                                ? null
                                : () => _handleDecision(req, approve: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Duyệt'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
