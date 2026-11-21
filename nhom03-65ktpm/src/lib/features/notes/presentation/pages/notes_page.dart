import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notes_cubit.dart';
import '../bloc/notes_state.dart';
import '../widgets/note_tile.dart';

/// Màn hình chính: danh sách ghi chú đọc từ Drift.
///
/// CRUD/soạn thảo thuộc issue #3, nên màn này chỉ đọc dữ liệu.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartNote')),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (BuildContext context, NotesState state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NotesStatus.failure) {
            return _Message(
              icon: Icons.error_outline,
              text: state.errorMessage ?? 'Đã xảy ra lỗi',
            );
          }
          if (state.notes.isEmpty) {
            return const _Message(
              icon: Icons.sticky_note_2_outlined,
              text: 'Chưa có ghi chú nào',
            );
          }
          return ListView.separated(
            itemCount: state.notes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              return NoteTile(note: state.notes[index]);
            },
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
