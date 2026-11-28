import 'package:flutter/material.dart';
import '../models/document_item.dart';

class DocumentCard extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback? onTap;
  final VoidCallback? onPreview;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final bool showDelete;
  final bool isSelected;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onPreview,
    this.onDownload,
    this.onDelete,
    this.showDelete = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = document.isPdf;
    final accentColor = isPdf ? const Color(0xFFD32F2F) : const Color(0xFF1565C0);
    final softBg = isPdf ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.amber.shade700 : Colors.grey.shade200,
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? Colors.amber.shade700 : Colors.black)
                .withValues(alpha: isSelected ? 0.12 : 0.04),
            blurRadius: isSelected ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // File type badge with selection indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: softBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Icon(
                          isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                          color: accentColor,
                          size: 26,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Document details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.fileName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: const Color(0xFF1A202C),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: softBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              document.fileType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Text(
                            document.formattedFileSize,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (document.topic != null && document.topic!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.label_outline_rounded, size: 12, color: Colors.grey.shade700),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      document.topic!,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
                    if (onPreview != null)
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF0D47A1),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        tooltip: 'Xem trước',
                        onPressed: onPreview,
                      ),
                    if (onDownload != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF334155),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        tooltip: 'Tải về',
                        onPressed: onDownload,
                      ),
                    ],
                    if (showDelete && onDelete != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2),
                          foregroundColor: Colors.red.shade600,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Xóa tài liệu',
                        onPressed: onDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
