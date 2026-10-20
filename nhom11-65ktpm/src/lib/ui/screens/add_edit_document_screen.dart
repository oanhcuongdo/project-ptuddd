import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../domain/models/document_type.dart';
import '../../state/document_provider.dart';

class AddEditDocumentScreen extends StatefulWidget {
  final Document? document;

  const AddEditDocumentScreen({super.key, this.document});

  @override
  State<AddEditDocumentScreen> createState() => _AddEditDocumentScreenState();
}

class _AddEditDocumentScreenState extends State<AddEditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _fileUrlController;

  String? _selectedSubjectFk;
  String _selectedDocType = 'lecture';
  int _selectedPriority = 1;
  String _selectedStatus = 'active';
  bool _isSaving = false;

  bool get isEditing => widget.document != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _contentController = TextEditingController(text: doc?.content ?? '');
    _fileUrlController = TextEditingController(text: doc?.fileUrl ?? '');
    _selectedSubjectFk = doc?.subjectFk;
    _selectedDocType = doc?.docType ?? 'lecture';
    _selectedPriority = doc?.priority ?? 1;
    _selectedStatus = doc?.status ?? 'active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<DocumentProvider>();

    try {
      if (isEditing) {
        await provider.updateDocument(
          documentPk: widget.document!.documentPk,
          title: _titleController.text,
          subjectFk: _selectedSubjectFk,
          docType: _selectedDocType,
          content: _contentController.text,
          fileUrl: _fileUrlController.text,
          priority: _selectedPriority,
          status: _selectedStatus,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật tài liệu thành công!')),
          );
          Navigator.pop(context);
        }
      } else {
        await provider.addDocument(
          title: _titleController.text,
          subjectFk: _selectedSubjectFk,
          docType: _selectedDocType,
          content: _contentController.text,
          fileUrl: _fileUrlController.text,
          priority: _selectedPriority,
          status: _selectedStatus,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm tài liệu mới thành công!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<DocumentProvider>().subjects;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa Tài liệu' : 'Thêm Tài liệu Mới'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _save,
            tooltip: 'Lưu',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Tiêu đề
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề tài liệu *',
                hintText: 'VD: Bài giảng Chương 1 - Kiến trúc Hệ thống',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề tài liệu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Chọn Môn học
            DropdownButtonFormField<String?>(
              value: _selectedSubjectFk,
              decoration: const InputDecoration(
                labelText: 'Môn học',
                prefixIcon: Icon(Icons.school),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('-- Chưa phân loại --'),
                ),
                ...subjects.map(
                  (s) => DropdownMenuItem(
                    value: s.subjectPk,
                    child: Text('${s.code} - ${s.name}'),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedSubjectFk = val),
            ),
            const SizedBox(height: 16),

            // Loại tài liệu
            const Text(
              'Loại tài liệu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: DocumentType.values.map((type) {
                return ButtonSegment<String>(
                  value: type.code,
                  label: Text(type.label),
                );
              }).toList(),
              selected: {_selectedDocType},
              onSelectionChanged: (set) {
                setState(() => _selectedDocType = set.first);
              },
            ),
            const SizedBox(height: 16),

            // Nội dung / Ghi chú tóm tắt
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Nội dung / Ghi chú tóm tắt',
                hintText: 'Nhập nội dung trọng tâm hoặc ghi chú học tập...',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // File URL / Link
            TextFormField(
              controller: _fileUrlController,
              decoration: const InputDecoration(
                labelText: 'Đường dẫn tệp / URL liên kết',
                hintText: 'VD: https://drive.google.com/... hoặc /docs/slide.pdf',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),

            // Độ ưu tiên
            const Text(
              'Độ ưu tiên',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Thấp')),
                    selected: _selectedPriority == 0,
                    selectedColor: Colors.green.withOpacity(0.3),
                    onSelected: (_) => setState(() => _selectedPriority = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Trung bình')),
                    selected: _selectedPriority == 1,
                    selectedColor: Colors.orange.withOpacity(0.3),
                    onSelected: (_) => setState(() => _selectedPriority = 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Cao')),
                    selected: _selectedPriority == 2,
                    selectedColor: Colors.red.withOpacity(0.3),
                    onSelected: (_) => setState(() => _selectedPriority = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trạng thái học tập
            const Text(
              'Trạng thái học tập',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Đang học')),
                    selected: _selectedStatus == 'active',
                    onSelected: (_) => setState(() => _selectedStatus = 'active'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Đã hoàn thành')),
                    selected: _selectedStatus == 'completed',
                    selectedColor: Colors.green.withOpacity(0.3),
                    onSelected: (_) => setState(() => _selectedStatus = 'completed'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Lưu Thay Đổi' : 'Tạo Tài Liệu'),
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
