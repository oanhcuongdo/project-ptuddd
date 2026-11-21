import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final logsAsync = widget.initialLogs != null
        ? AsyncValue.data(widget.initialLogs!)
        : ref.watch(adminSessionLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký & Minh chứng Buổi học')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm theo tiêu đề, phòng học hoặc Mentor...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                final filtered = logs.where((l) {
                  if (_searchQuery.isEmpty) return true;
                  return l.title.toLowerCase().contains(_searchQuery) ||
                      l.roomName.toLowerCase().contains(_searchQuery) ||
                      l.mentorName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Chưa có nhật ký buổi học nào.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final log = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          log.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${log.roomName} • Mentor: ${log.mentorName}',
                        ),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          if (log.guidedContent != null &&
                              log.guidedContent!.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Nội dung hướng dẫn: ${log.guidedContent}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Đối chiếu điểm danh & tự xác nhận:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (log.attendances.isEmpty)
                            const Text('Chưa có dữ liệu điểm danh.',
                                style: TextStyle(fontSize: 12))
                          else
                            ...log.attendances.map((a) {
                              final mentorPresent =
                                  a.mentorMarkedStatus == 'present';
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(a.menteeName)),
                                    Chip(
                                      label: Text(
                                        mentorPresent ? 'Có mặt' : 'Vắng',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Chip(
                                      label: Text(
                                        a.menteeConfirmed
                                            ? 'Đã xác nhận'
                                            : 'Chưa xác nhận',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          if (log.evidenceUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Minh chứng (${log.evidenceUrls.length} ảnh)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 90,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: log.evidenceUrls.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    log.evidenceUrls[i],
                                    width: 120,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 120,
                                      height: 90,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi tải nhật ký: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

