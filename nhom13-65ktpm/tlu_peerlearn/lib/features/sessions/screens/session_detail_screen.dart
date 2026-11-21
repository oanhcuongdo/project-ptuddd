import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tutoring_session.dart';
import '../services/sessions_service.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final TutoringSession session;
  final String currentUserId;
  final bool isMentor;
  final List<SessionAttendance>? initialAttendances;
  final List<SessionEvidence>? initialEvidences;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.currentUserId,
    this.isMentor = false,
    this.initialAttendances,
    this.initialEvidences,
  });

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  late TutoringSession _session;
  List<SessionAttendance> _attendances = [];
  List<SessionEvidence> _evidences = [];
  final Map<String, String> _markedStatus = {}; // menteeId -> 'present' | 'absent'

  bool _isLoading = true;
  bool _isSavingReport = false;
  bool _isConfirming = false;

  final _durationController = TextEditingController(text: '90');
  final _guidedContentController = TextEditingController();
  final _outcomesController = TextEditingController();
  final _issuesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    if (_session.actualDurationMinutes != null) {
      _durationController.text = '${_session.actualDurationMinutes}';
    }
    if (_session.guidedContent != null) {
      _guidedContentController.text = _session.guidedContent!;
    }
    if (_session.outcomes != null) {
      _outcomesController.text = _session.outcomes!;
    }
    if (_session.issues != null) {
      _issuesController.text = _session.issues!;
    }

    if (widget.initialAttendances != null && widget.initialEvidences != null) {
      _attendances = List.from(widget.initialAttendances!);
      _evidences = List.from(widget.initialEvidences!);
      for (final a in _attendances) {
        _markedStatus[a.menteeId] = a.mentorMarkedStatus;
      }
      _isLoading = false;
    } else {
      _loadDetails();
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _guidedContentController.dispose();
    _outcomesController.dispose();
    _issuesController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final service = ref.read(sessionsServiceProvider);
    final attendances = await service.fetchAttendances(_session.id);
    final evidences = await service.fetchEvidences(_session.id);

    if (mounted) {
      setState(() {
        _attendances = attendances;
        _evidences = evidences;
        for (final a in attendances) {
          _markedStatus[a.menteeId] = a.mentorMarkedStatus;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMentorReport() async {
    if (_guidedContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đã hướng dẫn')),
      );
      return;
    }

    setState(() => _isSavingReport = true);
    try {
      final service = ref.read(sessionsServiceProvider);
      await service.completeSessionReport(
        sessionId: _session.id,
        actualDurationMinutes: int.tryParse(_durationController.text) ?? 90,
        guidedContent: _guidedContentController.text.trim(),
        outcomes: _outcomesController.text.trim(),
        issues: _issuesController.text.trim(),
        attendanceStatuses: _markedStatus,
      );

      setState(() {
        _session = _session.copyWith(
          status: 'completed',
          actualDurationMinutes: int.tryParse(_durationController.text) ?? 90,
          guidedContent: _guidedContentController.text.trim(),
          outcomes: _outcomesController.text.trim(),
          issues: _issuesController.text.trim(),
        );
        _isSavingReport = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hoàn tất báo cáo buổi học thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingReport = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu báo cáo: $e')),
        );
      }
    }
  }

  Future<void> _confirmMenteeAttendance() async {
    setState(() => _isConfirming = true);
    try {
      final service = ref.read(sessionsServiceProvider);
      await service.confirmAttendanceByMentee(
        sessionId: _session.id,
        menteeId: widget.currentUserId,
      );

      setState(() {
        final idx = _attendances.indexWhere((a) => a.menteeId == widget.currentUserId);
        if (idx != -1) {
          _attendances[idx] = _attendances[idx].copyWith(
            menteeConfirmed: true,
            menteeConfirmedAt: DateTime.now(),
          );
        }
        _isConfirming = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác nhận tham gia buổi học thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xác nhận: $e')),
        );
      }
    }
  }

  Future<void> _mockUploadEvidence() async {
    // Quick demonstration helper for uploading evidence < 500KB (BR-04)
    final service = ref.read(sessionsServiceProvider);
    final mockBytes = Uint8List(200 * 1024); // 200KB < 500KB
    final evidence = await service.uploadEvidence(
      sessionId: _session.id,
      imageBytes: mockBytes,
      fileName: 'minh_chung_buoi_hoc.jpg',
      caption: 'Ảnh chụp minh chứng buổi học',
    );

    setState(() => _evidences.insert(0, evidence));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tải lên minh chứng buổi học thành công (< 500KB)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_session.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final myAttendance = _attendances.cast<SessionAttendance?>().firstWhere(
          (a) => a?.menteeId == widget.currentUserId,
          orElse: () => null,
        );

    final isMentee = !widget.isMentor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_session.title),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _session.isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _session.isCompleted ? 'ĐÃ HOÀN TẤT' : 'SẮP DIỄN RA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _session.isCompleted ? Colors.green.shade900 : Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Session Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _session.isOnline ? Icons.video_call : Icons.place,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _session.isOnline ? 'Học trực tuyến' : 'Học trực tiếp',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Thời gian: ${_session.scheduledStart.day}/${_session.scheduledStart.month}/${_session.scheduledStart.year} • ${_session.scheduledStart.hour.toString().padLeft(2, '0')}:${_session.scheduledStart.minute.toString().padLeft(2, '0')} - ${_session.scheduledEnd.hour.toString().padLeft(2, '0')}:${_session.scheduledEnd.minute.toString().padLeft(2, '0')}'),
                  if (_session.locationOrLink != null) ...[
                    const SizedBox(height: 4),
                    Text('Địa điểm / Link: ${_session.locationOrLink!}'),
                  ],
                  if (_session.plannedContent != null) ...[
                    const SizedBox(height: 8),
                    Text('Kế hoạch: ${_session.plannedContent!}', style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Mentee Independent Confirmation Banner (SES-03, BR-09, BR-10)
          if (isMentee && myAttendance != null)
            Card(
              color: myAttendance.menteeConfirmed ? Colors.green.shade50 : Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: myAttendance.menteeConfirmed ? Colors.green.shade300 : Colors.amber.shade300,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          myAttendance.menteeConfirmed ? Icons.check_circle : Icons.info_outline,
                          color: myAttendance.menteeConfirmed ? Colors.green : Colors.amber.shade900,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          myAttendance.menteeConfirmed
                              ? 'Bạn đã xác nhận tham gia buổi học (SES-03)'
                              : 'Xác nhận tham gia buổi học (SES-03)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: myAttendance.menteeConfirmed ? Colors.green.shade900 : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      myAttendance.menteeConfirmed
                          ? 'Thời gian xác nhận: ${myAttendance.menteeConfirmedAt?.hour}:${myAttendance.menteeConfirmedAt?.minute} ngày ${myAttendance.menteeConfirmedAt?.day}/${myAttendance.menteeConfirmedAt?.month}'
                          : 'Mentee tự xác nhận độc lập, không chặn báo cáo của Mentor (BR-09, BR-10).',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                    if (!myAttendance.menteeConfirmed) ...[
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        icon: const Icon(Icons.touch_app),
                        label: _isConfirming
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Bấm để xác nhận tham gia'),
                        onPressed: _isConfirming ? null : _confirmMenteeAttendance,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Attendance List (SES-02)
          Text(
            'Danh sách điểm danh thành viên',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_attendances.isEmpty)
            const Text('Chưa có danh sách thành viên điểm danh.')
          else
            ..._attendances.map((att) {
              final isPresent = _markedStatus[att.menteeId] == 'present';

              return Card(
                child: ListTile(
                  title: Text(att.menteeName ?? 'Sinh viên Mentee'),
                  subtitle: Text(
                    'Mentor đánh dấu: ${isPresent ? 'Có mặt' : 'Vắng mặt'} • Mentee: ${att.menteeConfirmed ? 'Đã xác nhận' : 'Chưa xác nhận'}',
                  ),
                  trailing: widget.isMentor && !_session.isCompleted
                      ? SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'present', label: Text('Có mặt')),
                            ButtonSegment(value: 'absent', label: Text('Vắng')),
                          ],
                          selected: {_markedStatus[att.menteeId] ?? 'absent'},
                          onSelectionChanged: (set) {
                            setState(() => _markedStatus[att.menteeId] = set.first);
                          },
                        )
                      : Chip(
                          label: Text(isPresent ? 'Có mặt' : 'Vắng mặt'),
                          backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                        ),
                ),
              );
            }),

          const SizedBox(height: 20),

          // Evidences Section (SES-02)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minh chứng buổi học (ảnh < 500KB)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (widget.isMentor && !_session.isCompleted)
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                  label: const Text('Thêm ảnh'),
                  onPressed: _mockUploadEvidence,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_evidences.isEmpty)
            Text('Chưa có ảnh minh chứng nào.', style: TextStyle(color: Colors.grey.shade600))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _evidences.map((e) {
                return Chip(
                  avatar: const Icon(Icons.image, size: 18),
                  label: Text(e.caption ?? 'Minh chứng'),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // Mentor Report Section (SES-02, BR-09)
          if (widget.isMentor) ...[
            Text(
              'Ghi nhận nội dung buổi học (Mentor)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              readOnly: _session.isCompleted,
              decoration: const InputDecoration(
                labelText: 'Thời lượng thực tế (phút) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _guidedContentController,
              maxLines: 3,
              readOnly: _session.isCompleted,
              decoration: const InputDecoration(
                labelText: 'Nội dung kiến thức đã hướng dẫn *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _outcomesController,
              maxLines: 2,
              readOnly: _session.isCompleted,
              decoration: const InputDecoration(
                labelText: 'Kết quả đạt được',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuesController,
              maxLines: 2,
              readOnly: _session.isCompleted,
              decoration: const InputDecoration(
                labelText: 'Vấn đề còn tồn tại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (!_session.isCompleted)
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: _isSavingReport
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Hoàn tất báo cáo buổi học (SES-02)'),
                onPressed: _isSavingReport ? null : _saveMentorReport,
              ),
          ],
        ],
      ),
    );
  }
}
