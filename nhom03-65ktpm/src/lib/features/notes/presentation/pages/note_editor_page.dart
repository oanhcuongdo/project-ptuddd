import 'dart:async';

import 'package:flutter/material.dart';

import '../../../summary/domain/repositories/summary_repository.dart';
import '../../../summary/presentation/pages/summary_page.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_cubit.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    required this.cubit,
    required this.summaryRepository,
    this.isSummaryDemo = false,
    this.note,
    this.initialKind = NoteKind.note,
    super.key,
  });

  final NotesCubit cubit;
  final SummaryRepository summaryRepository;
  final bool isSummaryDemo;
  final Note? note;
  final NoteKind initialKind;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  Timer? _saveTimer;
  Note? _note;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    if (_note?.isDiary ?? widget.initialKind == NoteKind.diary) {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _titleController = TextEditingController(
        text: _note?.title ?? 'Nhật ký $date',
      );
    } else {
      _titleController = TextEditingController(text: _note?.title ?? '');
    }
    _contentController = TextEditingController(text: _note?.content ?? '');
    _titleController.addListener(_scheduleSave);
    _contentController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    setState(() => _saving = true);
    _saveTimer = Timer(const Duration(milliseconds: 700), _save);
  }

  Future<void> _save() async {
    if (!mounted) return;
    try {
      if (_note == null) {
        _note = await widget.cubit.createNote(
          title: _titleController.text,
          content: _contentController.text,
          kind: widget.initialKind,
        );
      } else {
        await widget.cubit.updateNote(
          _note!,
          title: _titleController.text,
          content: _contentController.text,
        );
        _note = _note!.copyWith(
          title: _titleController.text,
          content: _contentController.text,
          updatedAt: DateTime.now(),
        );
      }
      if (mounted) setState(() => _saving = false);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Lưu nội dung đang gõ rồi mở màn tóm tắt AI (#12).
  ///
  /// Ghi chú mới chưa có trong database sẽ được tạo trước, nhờ vậy bản tóm tắt
  /// luôn gắn với một `noteId` thật.
  Future<void> _openSummary() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viết nội dung trước khi tóm tắt.')),
      );
      return;
    }
    _saveTimer?.cancel();
    if (_note?.title != _titleController.text ||
        _note?.content != _contentController.text) {
      await _save();
    }
    final note = _note;
    if (!mounted || note == null) {
      return;
    }
    await Navigator.of(context).push(
      SummaryPage.route(
        noteId: note.id,
        noteTitle: note.displayTitle,
        noteContent: _contentController.text,
        repository: widget.summaryRepository,
        isDemo: widget.isSummaryDemo,
      ),
    );
  }

  Future<void> _delete() async {
    if (_note == null) {
      Navigator.pop(context);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá ghi chú?'),
        content: const Text('Ghi chú sẽ được chuyển vào danh sách đã xoá.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.cubit.deleteNote(_note!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDiary = _note?.isDiary ?? widget.initialKind == NoteKind.diary;
    return Scaffold(
      appBar: AppBar(
        title: Text(isDiary ? 'Nhật ký hằng ngày' : 'Ghi chú'),
        actions: <Widget>[
          Text(
            _saving ? 'Đang lưu...' : 'Đã lưu',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Tóm tắt AI',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: _openSummary,
          ),
          IconButton(
            tooltip: 'Xoá',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
