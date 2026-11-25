import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/responsive_container.dart';
import '../models/tutoring_session.dart';
import '../services/sessions_service.dart';
import '../widgets/create_session_dialog.dart';
import 'session_detail_screen.dart';

class RoomSessionsTab extends ConsumerStatefulWidget {
  final String roomId;
  final String? currentUserId;
  final bool isMentor;

  const RoomSessionsTab({
    super.key,
    required this.roomId,
    this.currentUserId,
    this.isMentor = false,
  });

  @override
  ConsumerState<RoomSessionsTab> createState() => _RoomSessionsTabState();
}

class _RoomSessionsTabState extends ConsumerState<RoomSessionsTab> {
  void _openCreateSessionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CreateSessionDialog(
        onSubmit: ({
          required title,
          required scheduledStart,
          required scheduledEnd,
          required mode,
          locationOrLink,
          plannedContent,
        }) async {
          final service = ref.read(sessionsServiceProvider);
          await service.createSession(
            roomId: widget.roomId,
            mentorId: widget.currentUserId ?? 'mentor_user',
            title: title,
            scheduledStart: scheduledStart,
            scheduledEnd: scheduledEnd,
            mode: mode,
            locationOrLink: locationOrLink,
            plannedContent: plannedContent,
          );
          ref.invalidate(roomSessionsProvider(widget.roomId));
        },
      ),
    );
  }

  void _openSessionDetail(TutoringSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          session: session,
          currentUserId: widget.currentUserId ?? 'current_user',
          isMentor: widget.isMentor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(roomSessionsProvider(widget.roomId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roomSessionsProvider(widget.roomId));
        },
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Lỗi tải danh sách buổi học: $err')),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có lịch buổi học nào trong phòng.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isMentor
                          ? 'Bấm nút bên dưới để lên lịch buổi học đầu tiên.'
                          : 'Mentor sẽ lên lịch các buổi học hỗ trợ tại đây.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            final scheduled = sessions.where((s) => s.isScheduled).toList();
            final completed = sessions.where((s) => s.isCompleted).toList();

            return ResponsiveContainer(
              maxWidth: 860,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (scheduled.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.upcoming_outlined, size: 18, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          'Buổi học sắp diễn ra (${scheduled.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...scheduled.map(_buildSessionCard),
                    const SizedBox(height: 16),
                  ],
                  if (completed.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'Buổi học đã hoàn tất (${completed.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...completed.map(_buildSessionCard),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: widget.isMentor
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Lên lịch học'),
              onPressed: _openCreateSessionDialog,
            )
          : null,
    );
  }

  Widget _buildSessionCard(TutoringSession s) {
    final isOnline = s.isOnline;
    final isDone = s.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openSessionDetail(s),
        leading: CircleAvatar(
          backgroundColor: isDone
              ? Colors.green.shade100
              : (isOnline ? Colors.blue.shade100 : Colors.teal.shade100),
          child: Icon(
            isDone
                ? Icons.check
                : (isOnline ? Icons.video_call : Icons.meeting_room),
            color: isDone
                ? Colors.green.shade900
                : (isOnline ? Colors.blue.shade900 : Colors.teal.shade900),
          ),
        ),
        title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${s.scheduledStart.day}/${s.scheduledStart.month} • ${s.scheduledStart.hour.toString().padLeft(2, '0')}:${s.scheduledStart.minute.toString().padLeft(2, '0')} • ${isOnline ? 'Online' : 'Offline'}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
