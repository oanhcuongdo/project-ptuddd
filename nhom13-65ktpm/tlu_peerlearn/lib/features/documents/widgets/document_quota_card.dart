import 'package:flutter/material.dart';
import '../models/document_item.dart';

class DocumentQuotaCard extends StatelessWidget {
  final List<DocumentItem> documents;

  const DocumentQuotaCard({
    super.key,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    final totalBytes = documents.fold<int>(0, (sum, d) => sum + d.fileSize);
    final pdfCount = documents.where((d) => d.isPdf).length;
    final docxCount = documents.where((d) => d.isDocx).length;

    String formatBytes(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return Card(
      elevation: 0,
      color: Colors.blue.shade50.withValues(alpha: 0.6),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud_done_outlined, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kho học liệu phòng (${documents.length} tệp)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đã lưu: ${formatBytes(totalBytes)} • $pdfCount PDF • $docxCount DOCX',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
