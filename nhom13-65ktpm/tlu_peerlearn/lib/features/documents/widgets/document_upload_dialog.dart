import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../utils/document_validator.dart';

class DocumentUploadDialog extends StatefulWidget {
  final Future<void> Function({
    required String fileName,
    required Uint8List bytes,
    String? topic,
  }) onUpload;

  const DocumentUploadDialog({
    super.key,
    required this.onUpload,
  });

  @override
  State<DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _topicController = TextEditingController();

  Uint8List? _selectedBytes;
  String? _selectedFileName;
  String? _fileError;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickRealFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx'],
    );
    if (files.isEmpty) return;
    final file = files.single;
    final bytes = await file.xFile.readAsBytes();
    if (bytes.isEmpty) {
      setState(() => _fileError = 'Không đọc được dữ liệu tệp đã chọn.');
      return;
    }
    final error = DocumentValidator.validateUpload(
      fileName: file.name,
      sizeInBytes: bytes.length,
    );
    setState(() {
      _fileError = error;
      if (error == null) {
        _selectedFileName = file.name;
        _selectedBytes = bytes;
        if (_nameController.text.isEmpty) {
          _nameController.text = file.name;
        }
      } else {
        _selectedBytes = null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBytes == null || _selectedFileName == null) {
      setState(() {
        _fileError = 'Vui lòng chọn tệp tài liệu (.pdf hoặc .docx <= 5MB)';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onUpload(
        fileName: _nameController.text.trim(),
        bytes: _selectedBytes!,
        topic: _topicController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải tệp: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _selectedFileName != null && _selectedBytes != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF0D47A1), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tải lên tài liệu mới',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chỉ chấp nhận tệp .pdf hoặc .docx với dung lượng tối đa 5MB.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Modern dropzone-style picker box
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isLoading ? null : _pickRealFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: hasFile ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasFile ? Colors.green.shade400 : const Color(0xFFCBD5E1),
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                          size: 32,
                          color: hasFile ? Colors.green.shade600 : const Color(0xFF0D47A1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasFile ? 'Đã chọn: $_selectedFileName' : 'Chọn tệp từ thiết bị',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: hasFile ? Colors.green.shade800 : const Color(0xFF0D47A1),
                          ),
                        ),
                        if (hasFile) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${(_selectedBytes!.length / 1024).toStringAsFixed(1)} KB • Bấm để đổi tệp khác',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_fileError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _fileError!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên hiển thị tài liệu *',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tên tài liệu';
                    }
                    return DocumentValidator.validateFileType(val);
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _topicController,
                  decoration: InputDecoration(
                    labelText: 'Chủ đề trọng tâm (tùy chọn)',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.topic_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: const Text('Tải lên'),
        ),
      ],
    );
  }
}
