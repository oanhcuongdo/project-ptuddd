import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/document_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();
    final docs = provider.allDocuments;
    final subjects = provider.subjects;

    final totalDocs = docs.length;
    final lectures = docs.where((d) => d.docType == 'lecture').length;
    final assignments = docs.where((d) => d.docType == 'assignment').length;
    final references = docs.where((d) => d.docType == 'reference').length;
    final completed = docs.where((d) => d.status == 'completed').length;
    final active = totalDocs - completed;

    final completionRate = totalDocs > 0 ? (completed / totalDocs * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê Học tập'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tổng quan nhanh
          Row(
            children: [
              _buildStatCard(
                context,
                title: 'Tổng tài liệu',
                value: '$totalDocs',
                icon: Icons.description,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                title: 'Môn học',
                value: '${subjects.length}',
                icon: Icons.school,
                color: Colors.purple,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                title: 'Hoàn thành',
                value: '$completionRate%',
                icon: Icons.task_alt,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Phân loại theo loại tài liệu
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phân bố theo Loại tài liệu',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressRow('Bài giảng', lectures, totalDocs, Colors.blue),
                  const SizedBox(height: 12),
                  _buildProgressRow('Bài tập', assignments, totalDocs, Colors.orange),
                  const SizedBox(height: 12),
                  _buildProgressRow('Tài liệu tham khảo', references, totalDocs, Colors.teal),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tiến độ học tập
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ Học tập',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressRow('Đã hoàn thành', completed, totalDocs, Colors.green),
                  const SizedBox(height: 12),
                  _buildProgressRow('Đang học / Cần ôn tập', active, totalDocs, Colors.indigo),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phân bố theo môn học
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tài liệu theo Môn học',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (subjects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Chưa có môn học nào.'),
                    )
                  else
                    ...subjects.map((subj) {
                      final count = docs.where((d) => d.subjectFk == subj.subjectPk).length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${subj.code} - ${subj.name}'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count tài liệu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, int total, Color color) {
    final double ratio = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('$count / $total (${(ratio * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }
}
