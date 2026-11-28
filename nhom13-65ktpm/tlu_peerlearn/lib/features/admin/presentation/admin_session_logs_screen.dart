import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/responsive_container.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

class AdminSessionLogsScreen extends ConsumerStatefulWidget {
  final List<AdminSessionLog>? initialLogs;

  const AdminSessionLogsScreen({super.key, this.initialLogs});

  @override
  ConsumerState<AdminSessionLogsScreen> createState() =>
      _AdminSessionLogsScreenState();
}

class _AdminSessionLogsScreenState
    extends ConsumerState<AdminSessionLogsScreen> {
  String _searchQuery = '';
  String? _selectedMentor;

  void _showEvidenceZoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = widget.initialLogs != null
        ? AsyncValue.data(widget.initialLogs!)
        : ref.watch(adminSessionLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký & Minh chứng Buổi học')),
      body: ResponsiveContainer(
        maxWidth: 1000,
        padding: EdgeInsets.zero,
        child: logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi tải nhật ký: $e')),
          data: (logs) {
            final mentors = logs.map((l) => l.mentorName).toSet().toList()
              ..sort();

            final filtered = logs.where((l) {
              if (_selectedMentor != null && l.mentorName != _selectedMentor) {
                return false;
              }
              if (_searchQuery.isEmpty) return true;
              final matchesMentee = l.attendances.any(
                (a) => a.menteeName.toLowerCase().contains(_searchQuery),
              );
              return l.title.toLowerCase().contains(_searchQuery) ||
                  l.roomName.toLowerCase().contains(_searchQuery) ||
                  l.mentorName.toLowerCase().contains(_searchQuery) ||
                  matchesMentee;
            }).toList();

            final Map<String, List<AdminSessionLog>> grouped = {};
            for (final log in filtered) {
              grouped.putIfAbsent(log.roomName, () => []).add(log);
            }
            final roomNames = grouped.keys.toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 640;
                      final searchField = TextField(
                        decoration: const InputDecoration(
                          hintText:
                              'Tìm theo buổi học, phòng, Mentor hoặc Mentee...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(
                          () => _searchQuery = v.trim().toLowerCase(),
                        ),
                      );
                      final mentorDropdown = DropdownButtonFormField<String?>(
                        initialValue: _selectedMentor,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Lọc theo Mentor',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Tất cả Mentor'),
                          ),
                          ...mentors.map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedMentor = v),
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(flex: 2, child: searchField),
                            const SizedBox(width: 12),
                            Expanded(child: mentorDropdown),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          searchField,
                          const SizedBox(height: 10),
                          mentorDropdown,
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('Chưa có nhật ký buổi học nào phù hợp.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: roomNames.length,
                          itemBuilder: (context, index) {
                            final roomName = roomNames[index];
                            final roomLogs = grouped[roomName]!;
                            final mentorName = roomLogs.first.mentorName;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(
                                    Icons.meeting_room_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  roomName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Mentor: $mentorName • ${roomLogs.length} buổi học',
                                ),
                                childrenPadding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                children: roomLogs.map((log) {
                                  return Card(
                                    elevation: 0,
                                    color: const Color(0xFFF8FAFD),
                                    margin: const EdgeInsets.only(top: 8),
                                    child: ExpansionTile(
                                      title: Text(
                                        log.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${log.attendances.length} học viên • ${log.evidenceUrls.length} ảnh minh chứng',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      childrenPadding: const EdgeInsets.all(12),
                                      children: [
                                        if (log.guidedContent != null &&
                                            log.guidedContent!.isNotEmpty) ...[
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Text(
                                              'Nội dung hướng dẫn: ${log.guidedContent}',
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Đối chiếu điểm danh & tự xác nhận:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (log.attendances.isEmpty)
                                          const Text(
                                            'Chưa có dữ liệu điểm danh.',
                                            style: TextStyle(fontSize: 12),
                                          )
                                        else
                                          ...log.attendances.map((a) {
                                            final mentorPresent =
                                                a.mentorMarkedStatus ==
                                                    'present';
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      a.menteeName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  _StatusBadge(
                                                    text: mentorPresent
                                                        ? 'Có mặt'
                                                        : 'Vắng',
                                                    color: mentorPresent
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _StatusBadge(
                                                    text: a.menteeConfirmed
                                                        ? 'Đã xác nhận'
                                                        : 'Chưa xác nhận',
                                                    color: a.menteeConfirmed
                                                        ? Colors.blue
                                                        : Colors.orange,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        if (log.evidenceUrls.isNotEmpty) ...[
                                          const SizedBox(height: 14),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Minh chứng (${log.evidenceUrls.length} ảnh — bấm để phóng to)',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: log.evidenceUrls.map((u) {
                                              return InkWell(
                                                onTap: () =>
                                                    _showEvidenceZoom(
                                                  context,
                                                  u,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      width: 110,
                                                      height: 90,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        border: Border.all(
                                                          color: Colors
                                                              .grey.shade300,
                                                        ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(9),
                                                        child: Image.network(
                                                          u,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (_, _, _) =>
                                                                  const Icon(
                                                            Icons.broken_image,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      right: 4,
                                                      bottom: 4,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black54,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.zoom_in,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
