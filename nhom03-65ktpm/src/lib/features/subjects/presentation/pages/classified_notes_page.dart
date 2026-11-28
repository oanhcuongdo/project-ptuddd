import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/classified_note.dart';
import '../bloc/subjects_cubit.dart';
import '../bloc/subjects_state.dart';
import '../widgets/note_classification_sheet.dart';
import '../widgets/note_filter_bar.dart';
import '../widgets/subject_color_dot.dart';
import 'subject_manager_page.dart';

/// Danh sách ghi chú lọc theo môn học và tag; chạm vào ghi chú để gán môn, tag.
///
/// Cần [SubjectsCubit] được provide ở phía trên.
class ClassifiedNotesPage extends StatelessWidget {
  const ClassifiedNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubjectsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân loại ghi chú'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('open-subject-manager'),
            tooltip: 'Môn học & tag',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider<SubjectsCubit>.value(
                  value: cubit,
                  child: const SubjectManagerPage(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<SubjectsCubit, SubjectsState>(
        // Lỗi đồng bộ không chặn màn hình: báo bằng SnackBar, dữ liệu trên máy
        // vẫn hiển thị.
        listenWhen: (SubjectsState previous, SubjectsState current) =>
            current.status == SubjectsStatus.success &&
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        listener: (BuildContext context, SubjectsState state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!))),
        builder: (BuildContext context, SubjectsState state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SubjectsStatus.failure) {
            return Center(child: Text(state.errorMessage ?? 'Đã xảy ra lỗi'));
          }
          return Column(
            children: <Widget>[
              NoteFilterBar(
                subjects: state.subjects,
                tags: state.tags,
                filter: state.filter,
                onChanged: cubit.setFilter,
              ),
              const Divider(height: 1),
              Expanded(child: _buildList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, SubjectsState state) {
    final notes = state.visibleNotes;
    if (state.notes.isEmpty) {
      return const Center(child: Text('Chưa có ghi chú nào'));
    }
    if (notes.isEmpty) {
      return const Center(child: Text('Không có ghi chú phù hợp.'));
    }
    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) =>
          _NoteRow(note: notes[index], state: state),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.state});

  final ClassifiedNote note;
  final SubjectsState state;

  Future<void> _classify(BuildContext context) async {
    final cubit = context.read<SubjectsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await NoteClassificationSheet.show(
      context,
      note: note,
      subjects: state.subjects,
      tags: state.tags,
    );
    if (result == null) return;
    final error = await cubit.classifyNote(
      note.id,
      subjectId: result.subjectId,
      tags: result.tags,
    );
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = state.subjectById(note.subjectId);
    return ListTile(
      key: ValueKey<String>('classified-note-${note.id}'),
      title: Text(note.displayTitle),
      subtitle: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (subject != null) ...<Widget>[
            SubjectColorDot(color: subject.color),
            Text(subject.name),
          ] else
            const Text('Chưa phân loại'),
          for (final tag in note.tags) Text('#$tag'),
        ],
      ),
      trailing: const Icon(Icons.label_outline),
      onTap: () => _classify(context),
    );
  }
}
