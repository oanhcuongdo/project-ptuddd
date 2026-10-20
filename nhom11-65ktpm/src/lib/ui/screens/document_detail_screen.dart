import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../domain/models/document_type.dart';
import '../../state/document_provider.dart';
import 'add_edit_document_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final String documentPk;

  const DocumentDetailScreen({super.key, required this.documentPk});

  void _showDeleteDialog(BuildContext context, Document doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${doc.title}"?\n'
          'Thao tác này sẽ ghi nhận vết vào bảng DeleteLogs (Tombstone) theo nguyên lý Kiến trúc Cashew.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<DocumentProvider>().deleteDocument(doc.documentPk);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tài liệu và tạo DeleteLog Tombstone!')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();
    final docs = provider.allDocuments.where((d) => d.documentPk == documentPk).toList();

    if (docs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết Tài liệu')),
        body: const Center(child: Text('Tài liệu không tồn tại hoặc đã bị xóa.')),
      );
    }

    final doc = docs.first;
    final subject = doc.subjectFk != null ? provider.subjectMap[doc.subjectFk] : null;
    final docType = DocumentType.fromCode(doc.docType);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Tài liệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditDocumentScreen(document: doc),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Xóa',
            onPressed: () => _showDeleteDialog(context, doc),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Badges Row
          Row(
            children: [
              Chip(
                avatar: const Icon(Icons.category, size: 16),
                label: Text(docType.label),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              const SizedBox(width: 8),
              if (subject != null)
                Chip(
                  avatar: const Icon(Icons.school, size: 16),
                  label: Text('${subject.code} - ${subject.name}'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            doc.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Content Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Nội dung / Tóm tắt',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    doc.content?.isNotEmpty == true
                        ? doc.content!
                        : 'Không có ghi chú tóm tắt.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // File URL Card (if any)
          if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.attachment, color: Colors.blue),
                title: const Text('Tệp đính kèm / Liên kết'),
                subtitle: Text(
                  doc.fileUrl!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Sao chép liên kết',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: doc.fileUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép liên kết!')),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Metadata Card (Cashew Architecture Highlights: UUID, Timestamps, LWW)
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông số Kiến trúc Hệ thống (Cashew Metadata)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Divider(),
                  _buildMetaRow('Khóa chính (UUID v4)', doc.documentPk),
                  _buildMetaRow('Độ ưu tiên', doc.priority == 2 ? 'Cao' : (doc.priority == 1 ? 'Trung bình' : 'Thấp')),
                  _buildMetaRow('Trạng thái', doc.status == 'completed' ? 'Đã hoàn thành' : 'Đang học'),
                  _buildMetaRow('Ngày tạo', dateFormat.format(doc.dateTimeCreated)),
                  _buildMetaRow('Ngày cập nhật (LWW)', dateFormat.format(doc.dateTimeModified)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
