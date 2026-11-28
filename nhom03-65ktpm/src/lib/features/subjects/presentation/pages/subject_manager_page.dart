import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/subject.dart';
import '../bloc/subjects_cubit.dart';
import '../bloc/subjects_state.dart';
import '../widgets/subject_color_dot.dart';

/// Quản lý môn học (thêm, sửa, xoá) và tag (đổi tên, xoá trên mọi ghi chú).
///
/// Cần [SubjectsCubit] được provide ở phía trên.
class SubjectManagerPage extends StatelessWidget {
  const SubjectManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Môn học & tag'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Môn học'),
              Tab(text: 'Tag'),
            ],
          ),
        ),
        body: BlocBuilder<SubjectsCubit, SubjectsState>(
          builder: (BuildContext context, SubjectsState state) => TabBarView(
            children: <Widget>[
              _SubjectList(subjects: state.subjects),
              _TagList(tags: state.tags),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey<String>('add-subject'),
          onPressed: () => _addSubject(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm môn học'),
        ),
      ),
    );
  }

  Future<void> _addSubject(BuildContext context) async {
    final cubit = context.read<SubjectsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await _NameDialog.show(
      context,
      title: 'Thêm môn học',
      withColor: true,
    );
    if (result == null) return;
    _showError(
      messenger,
      await cubit.addSubject(result.name, color: result.color),
    );
  }
}

class _SubjectList extends StatelessWidget {
  const _SubjectList({required this.subjects});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const _Hint('Chưa có môn học. Bấm "Thêm môn học" để tạo.');
    }
    return ListView(
      children: <Widget>[
        for (final subject in subjects)
          ListTile(
            key: ValueKey<String>('subject-${subject.id}'),
            leading: SubjectColorDot(color: subject.color, size: 18),
            title: Text(subject.name),
            onTap: () => _edit(context, subject),
            trailing: IconButton(
              tooltip: 'Xoá môn học',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(
                context,
                'Xoá môn "${subject.name}"? Các ghi chú của môn này sẽ chuyển '
                'sang "Chưa phân loại".',
                (SubjectsCubit cubit) => cubit.deleteSubject(subject.id),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, Subject subject) async {
    final cubit = context.read<SubjectsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await _NameDialog.show(
      context,
      title: 'Sửa môn học',
      initialName: subject.name,
      initialColor: subject.color,
      withColor: true,
    );
    if (result == null) return;
    _showError(
      messenger,
      await cubit.updateSubject(
        subject,
        name: result.name,
        color: result.color,
      ),
    );
  }
}

class _TagList extends StatelessWidget {
  const _TagList({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const _Hint(
        'Chưa có tag. Tag được tạo khi gán cho ghi chú ở màn "Phân loại ghi chú".',
      );
    }
    return ListView(
      children: <Widget>[
        for (final tag in tags)
          ListTile(
            key: ValueKey<String>('tag-$tag'),
            leading: const Icon(Icons.sell_outlined),
            title: Text('#$tag'),
            onTap: () => _rename(context, tag),
            trailing: IconButton(
              tooltip: 'Xoá tag',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(
                context,
                'Xoá tag "#$tag"? Tag sẽ được gỡ khỏi mọi ghi chú.',
                (SubjectsCubit cubit) => cubit.deleteTag(tag),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _rename(BuildContext context, String tag) async {
    final cubit = context.read<SubjectsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await _NameDialog.show(
      context,
      title: 'Đổi tên tag',
      initialName: tag,
    );
    if (result == null) return;
    _showError(messenger, await cubit.renameTag(tag, result.name));
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  String message,
  Future<String?> Function(SubjectsCubit cubit) onDelete,
) async {
  final cubit = context.read<SubjectsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Xác nhận xoá'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          key: const ValueKey<String>('confirm-delete'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Xoá'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  _showError(messenger, await onDelete(cubit));
}

void _showError(ScaffoldMessengerState messenger, String? error) {
  if (error == null) return;
  messenger.showSnackBar(SnackBar(content: Text(error)));
}

class _Hint extends StatelessWidget {
  const _Hint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _NameResult {
  const _NameResult(this.name, this.color);

  final String name;
  final String? color;
}

/// Hộp nhập tên (kèm chọn màu nếu là môn học).
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initialName,
    required this.initialColor,
    required this.withColor,
  });

  final String title;
  final String initialName;
  final String? initialColor;
  final bool withColor;

  static Future<_NameResult?> show(
    BuildContext context, {
    required String title,
    String initialName = '',
    String? initialColor,
    bool withColor = false,
  }) {
    return showDialog<_NameResult>(
      context: context,
      builder: (_) => _NameDialog(
        title: title,
        initialName: initialName,
        initialColor: initialColor ?? subjectColorPalette.first,
        withColor: withColor,
      ),
    );
  }

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late String? _color = widget.initialColor;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(
    context,
    _NameResult(_name.text, widget.withColor ? _color : null),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('name-field'),
            controller: _name,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Tên'),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.withColor) _buildPalette(context),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          key: const ValueKey<String>('name-save'),
          onPressed: _submit,
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  Widget _buildPalette(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final color in subjectColorPalette)
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => setState(() => _color = color),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: color == _color
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                ),
              ),
              child: SubjectColorDot(color: color, size: 24),
            ),
          ),
      ],
    );
  }
}
