import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_item.dart';
import '../services/document_service.dart';
import '../utils/docx_byte_extractor.dart';
import '../utils/file_downloader.dart';
import '../utils/text_extractor.dart';
import '../utils/topic_keyword_extractor.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final DocumentItem document;
  final String? extractedText;
  final VoidCallback? onGenerateAi;
  final Future<void> Function()? onDownload;

  const DocumentPreviewScreen({
    super.key,
    required this.document,
    this.extractedText,
    this.onGenerateAi,
    this.onDownload,
  });

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  String? _loadedText;
  bool _isExtracting = false;
  String? _extractNote;

  @override
  void initState() {
    super.initState();
    if (widget.extractedText != null && widget.extractedText!.trim().isNotEmpty) {
      _loadedText = widget.extractedText;
    } else if (!widget.document.isPdf) {
      _autoExtractDocx();
    }
  }

  Future<void> _autoExtractDocx() async {
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      client = null;
    }
    if (client == null) return;

    setState(() => _isExtracting = true);
    try {
      final service = DocumentService(client);
      final bytes = await service.downloadDocumentBytes(widget.document.fileUrl);
      if (bytes != null && bytes.isNotEmpty) {
        final extracted = await DocxByteExtractor.extractTextFromDocxBytes(bytes);
        if (mounted) {
          setState(() {
            _loadedText = extracted.isNotEmpty ? extracted : null;
            if (extracted.isEmpty) {
              _extractNote = 'Không tìm thấy đoạn văn bản thuần trong tệp Word này.';
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _extractNote = 'Không thể tự động đọc nội dung tệp. Bạn có thể tải về máy để xem.';
        });
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _handleDownload(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.onDownload != null) {
      await widget.onDownload!();
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('Đang tải "${widget.document.fileName}"...')),
    );

    try {
      final started = await downloadFileFromUrl(
        url: widget.document.fileUrl,
        fileName: widget.document.fileName,
      );
      if (!started) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Không thể tải tệp tự động. Bạn có thể bấm nút sao chép liên kết ở góc trên.'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi tải tệp: $e')),
      );
    }
  }

  Future<void> _handleOpenDirect(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await openFileInBrowser(widget.document.fileUrl);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không thể mở tệp trực tiếp. Hãy bấm "Tải về máy".')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = widget.document;
    final isPdf = doc.isPdf;
    final displayText = _loadedText;
    final hasText = displayText != null && displayText.trim().isNotEmpty;
    final accentColor = isPdf ? const Color(0xFFD32F2F) : const Color(0xFF0D47A1);
    final softBg = isPdf ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD);
    final keywords = TopicKeywordExtractor.extractKeywords(
      hasText ? displayText : '${doc.fileName} ${doc.topic ?? ""}',
      topN: 6,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Chi tiết tài liệu', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Sao chép liên kết tệp',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: doc.fileUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép liên kết tài liệu!')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Polished Hero Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: softBg,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                              color: accentColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.fileName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: softBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        doc.fileType.toUpperCase(),
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      doc.formattedFileSize,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (doc.topic != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Chủ đề: ${doc.topic}',
                                          style: const TextStyle(
                                            color: Color(0xFF1D4ED8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Action buttons row
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (isPdf)
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              label: const Text('Xem trực tiếp PDF'),
                              onPressed: () => _handleOpenDirect(context),
                            ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Tải về máy'),
                            onPressed: () => _handleDownload(context),
                          ),
                          if (widget.onGenerateAi != null)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.amber.shade800,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Tạo đề AI', style: TextStyle(fontWeight: FontWeight.w600)),
                              onPressed: widget.onGenerateAi,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Keywords chip bar
                if (keywords.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tag_rounded, size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Từ khóa trọng tâm nhận diện',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: keywords
                              .map(
                                (kw) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    '# $kw',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Extracted text viewer card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.article_outlined, size: 19, color: Color(0xFF0D47A1)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Nội dung trích xuất',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (hasText) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${displayText.length} / ${TextExtractor.maxCharacters}',
                                  style: const TextStyle(
                                    color: Color(0xFF0D47A1),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.content_copy_rounded, size: 17),
                                tooltip: 'Sao chép nội dung trích xuất',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: displayText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã sao chép văn bản trích xuất!')),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(18),
                        constraints: const BoxConstraints(minHeight: 200),
                        child: _isExtracting
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 36),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 14),
                                      Text('Đang trích xuất nội dung văn bản từ tệp...'),
                                    ],
                                  ),
                                ),
                              )
                            : hasText
                                ? SelectableText(
                                    displayText,
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      height: 1.65,
                                      fontSize: 14,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPdf
                                            ? 'Tệp định dạng PDF được hỗ trợ xem nguyên bản trên trình duyệt. Bấm nút "Xem trực tiếp PDF" ở trên để đọc toàn bộ tài liệu, hoặc bấm "Tạo đề AI" để sinh câu hỏi và flashcard ôn tập.'
                                            : (_extractNote ??
                                                'Chưa có nội dung văn bản trích xuất từ tệp này. Nhấn "Tạo đề AI" để trích xuất và sinh câu hỏi tự động.'),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          height: 1.6,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      if (isPdf) ...[
                                        const SizedBox(height: 14),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD32F2F)),
                                          label: const Text('Mở xem tệp PDF trong tab mới'),
                                          onPressed: () => _handleOpenDirect(context),
                                        ),
                                      ],
                                    ],
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
