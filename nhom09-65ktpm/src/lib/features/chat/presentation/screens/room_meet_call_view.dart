import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/meet_session_model.dart';
import '../components/jitsi_meet_frame.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_styles.dart';

/// Màn hình Video Call Jitsi Meet nhúng trực tiếp trong BuddyTalk kèm Đồng hồ điểm danh:
/// Học đủ `session.minMinutes` trong buổi học -> tự động 🔥 +1 Chuỗi phòng.
class RoomMeetCallView extends StatefulWidget {
  final ConversationModel room;
  final MeetSessionModel session;
  final VoidCallback onExit;

  const RoomMeetCallView({
    super.key,
    required this.room,
    required this.session,
    required this.onExit,
  });

  @override
  State<RoomMeetCallView> createState() => _RoomMeetCallViewState();
}

class _RoomMeetCallViewState extends State<RoomMeetCallView> {
  Timer? _timer;
  int _attendedSeconds = 0;
  bool _streakAwarded = false;
  bool _isAwarding = false;
  String _serverId = 'jitsi_riot';
  late final String _displayName;
  late final ChatProvider _chatProvider;
  String? _userId;

  String get _meetUrl =>
      widget.session.buildMeetUrl(_displayName, serverId: _serverId);

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    final profile = context.read<AuthProvider>().currentProfile;
    _userId = profile?.userId;
    _displayName = (profile?.displayName.trim().isNotEmpty ?? false)
        ? profile!.displayName
        : 'BuddyTalk Learner';

    _initAttendanceAndStartTimer();
  }

  Future<void> _initAttendanceAndStartTimer() async {
    final uid = _userId;
    if (uid != null) {
      final att = await _chatProvider.fetchMyMeetAttendance(
        sessionId: widget.session.id,
        userId: uid,
      );
      if (!mounted) return;
      setState(() {
        _attendedSeconds = att.attendedSeconds;
        _streakAwarded = att.streakAwarded;
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> _onTick() async {
    if (!mounted) return;
    setState(() => _attendedSeconds++);

    final uid = _userId;
    if (uid == null) return;

    // Đủ số phút tối thiểu của buổi Meet -> tự động điểm danh & cộng chuỗi phòng!
    if (!_streakAwarded &&
        !_isAwarding &&
        _attendedSeconds >= widget.session.requiredSeconds) {
      _isAwarding = true;
      final res = await _chatProvider.awardMeetStreak(
        sessionId: widget.session.id,
        conversationId: widget.room.id,
        userId: uid,
        attendedSeconds: _attendedSeconds,
        addMinutesToDaily: widget.session.minMinutes,
        dailyGoalMinutes: widget.session.minMinutes,
      );

      if (!mounted) return;
      setState(() {
        _streakAwarded = true;
        _isAwarding = false;
      });

      final streakMsg = res.roomStreak != null
          ? '🔥 Đủ ${widget.session.minMinutes} phút! Chuỗi phòng "${widget.room.name}" đã lên ${res.roomStreak} ngày!'
          : '🔥 Xuất sắc! Bạn đã hoàn thành đủ ${widget.session.minMinutes} phút trong buổi học!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.streakOrange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Text(
            streakMsg,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }

    // Lưu tiến độ định kỳ mỗi 15 giây để tránh mất phút nếu lỡ rớt mạng
    if (_attendedSeconds % 15 == 0) {
      _chatProvider.saveMeetProgress(
        sessionId: widget.session.id,
        userId: uid,
        attendedSeconds: _attendedSeconds,
        streakAwarded: _streakAwarded,
      );
    }
  }

  Future<void> _handleExit() async {
    _timer?.cancel();
    final uid = _userId;
    if (uid != null) {
      await _chatProvider.saveMeetProgress(
        sessionId: widget.session.id,
        userId: uid,
        attendedSeconds: _attendedSeconds,
        streakAwarded: _streakAwarded,
      );
    }

    if (!mounted) return;
    if (!_streakAwarded) {
      final remainSec =
          (widget.session.requiredSeconds - _attendedSeconds).clamp(0, 99999);
      final remainMin = (remainSec / 60).ceil();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu ${_formatDuration(_attendedSeconds)}. Cần học thêm khoảng $remainMin phút nữa trong buổi này để lên chuỗi phòng!',
          ),
        ),
      );
    }
    widget.onExit();
  }

  Future<void> _openAttendanceDialog() async {
    final list = await _chatProvider.fetchSessionAttendances(widget.session.id);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Điểm danh buổi học Meet',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 380,
          child: list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Chưa có dữ liệu điểm danh được ghi nhận.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 12, color: AppColors.divider),
                  itemBuilder: (_, idx) {
                    final item = list[idx];
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                'Thời gian học: ${_formatDuration(item.attendedSeconds)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.streakAwarded
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.streakAwarded ? '✓ Đã lên chuỗi' : 'Đang học',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: item.streakAwarded
                                  ? const Color(0xFF047857)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_attendedSeconds / widget.session.requiredSeconds)
        .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          children: [
            // Thanh điều khiển Meet + Đồng hồ tiến độ 2 tầng (giãn full chiều ngang)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF0F172A),
              child: Wrap(
                spacing: 14,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Trái: Tên buổi học
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Phòng: ${widget.room.name}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Giữa: Đồng hồ điểm danh chuỗi phòng + Mục tiêu ngày cá nhân
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _streakAwarded
                            ? const Color(0xFF10B981)
                            : ChatStyles.tealPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _streakAwarded
                                  ? Icons.check_circle_rounded
                                  : Icons.local_fire_department_rounded,
                              size: 16,
                              color: _streakAwarded
                                  ? const Color(0xFF34D399)
                                  : AppColors.streakOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _streakAwarded
                                  ? 'Đã đủ ${widget.session.minMinutes} phút • Đã cộng chuỗi phòng!'
                                  : 'Chuỗi phòng: ${_formatDuration(_attendedSeconds)} / ${_formatDuration(widget.session.requiredSeconds)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 260,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _streakAwarded ? 1.0 : progress,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.14),
                              color: _streakAwarded
                                  ? const Color(0xFF34D399)
                                  : ChatStyles.tealLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Phải: Chuyển server dự phòng + Điểm danh + Mở tab mới + Rời buổi học
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: 'Đổi máy chủ Video Call',
                        onSelected: (id) => setState(() => _serverId = id),
                        itemBuilder: (_) => MeetSessionModel.meetServers
                            .map(
                              (s) => PopupMenuItem<String>(
                                value: s.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      s.id == _serverId
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 16,
                                      color: s.id == _serverId
                                          ? ChatStyles.tealPrimary
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(s.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.dns_outlined,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                MeetSessionModel.meetServers
                                    .firstWhere((s) => s.id == _serverId)
                                    .label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openAttendanceDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: const Icon(Icons.fact_check_outlined, size: 16),
                        label: const Text('Điểm danh'),
                      ),
                      IconButton(
                        onPressed: () => openMeetInNewTab(_meetUrl),
                        tooltip: 'Mở Meet ở tab mới',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      ),
                      FilledButton.icon(
                        onPressed: _handleExit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: const Icon(Icons.call_end_rounded, size: 16),
                        label: const Text('Rời buổi học'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Khung Jitsi Meet nhúng trực tiếp (tự reload khi đổi máy chủ)
            Expanded(
              child: JitsiMeetFrame(
                key: ValueKey(_meetUrl),
                meetUrl: _meetUrl,
                roomTitle: widget.session.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
