import 'package:flutter/material.dart';
import '../models/document_item.dart';

class DocumentCard extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final bool showDelete;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDownload,
    this.onDelete,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = document.isPdf;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge icon for file type
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf : Icons.description,
                    color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Document details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (document.topic != null && document.topic!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.label_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              document.topic!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Text(
                          document.formattedFileSize,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        Text(
                          document.fileType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPdf ? Colors.red.shade600 : Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onDownload != null)
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      tooltip: 'Tải về',
                      onPressed: onDownload,
                    ),
                  if (showDelete && onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Xóa tài liệu',
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
