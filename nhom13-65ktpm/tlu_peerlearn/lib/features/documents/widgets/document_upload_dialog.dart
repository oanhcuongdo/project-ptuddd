import 'dart:typed_data';
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

  void _onMockFileSelect(String name, int size) {
    final error = DocumentValidator.validateUpload(
      fileName: name,
      sizeInBytes: size,
    );

    setState(() {
      _fileError = error;
      if (error == null) {
        _selectedFileName = name;
        _nameController.text = name;
        _selectedBytes = Uint8List(size);
      } else {
        _selectedFileName = null;
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
    return AlertDialog(
      title: const Text('Tải lên tài liệu mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chỉ chấp nhận tệp .pdf hoặc .docx với dung lượng tối đa 5MB (BR-04).',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // File picker placeholder buttons
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _selectedFileName != null
                      ? 'Đã chọn: $_selectedFileName'
                      : 'Chọn tệp từ thiết bị',
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        // Quick selector demo helper for testing or direct picking
                        _onMockFileSelect('Tai_lieu_hoc_tap.pdf', 1024 * 1024);
                      },
              ),
              if (_fileError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _fileError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị tài liệu *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
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
                decoration: const InputDecoration(
                  labelText: 'Chủ đề trọng tâm (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.topic_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Tải lên'),
        ),
      ],
    );
  }
}
