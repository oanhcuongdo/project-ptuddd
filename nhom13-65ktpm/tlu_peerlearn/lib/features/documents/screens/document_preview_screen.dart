import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/document_item.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final DocumentItem document;
  final String? extractedText;
  final VoidCallback? onGenerateAi;

  const DocumentPreviewScreen({
    super.key,
    required this.document,
    this.extractedText,
    this.onGenerateAi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = document.isPdf;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Sao chép liên kết tệp',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: document.fileUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép liên kết tài liệu!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          isPdf ? Icons.picture_as_pdf : Icons.description,
                          color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.fileName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${document.fileType.toUpperCase()} • ${document.formattedFileSize}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          if (document.topic != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Chủ đề: ${document.topic}',
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Tải về máy'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đang tải "${document.fileName}"...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade800),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Tạo đề AI'),
                    onPressed: onGenerateAi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Extracted text preview
            Text(
              'Nội dung trích xuất (Tối đa 15.000 ký tự cho AI - BR-04):',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: const BoxConstraints(minHeight: 180),
              child: Text(
                (extractedText != null && extractedText!.trim().isNotEmpty)
                    ? extractedText!
                    : 'Chưa có nội dung văn bản trích xuất từ tệp này. Nhấn "Tạo đề AI" để trích xuất và sinh câu hỏi tự động.',
                style: TextStyle(
                  color: (extractedText != null && extractedText!.trim().isNotEmpty)
                      ? Colors.black87
                      : Colors.grey.shade600,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
