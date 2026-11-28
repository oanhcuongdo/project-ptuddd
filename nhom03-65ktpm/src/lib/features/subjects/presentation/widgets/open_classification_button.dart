import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/note_classification_repository.dart';
import '../../domain/repositories/subject_repository.dart';
import '../bloc/subjects_cubit.dart';
import '../pages/classified_notes_page.dart';

/// Nút trên AppBar mở màn "Phân loại ghi chú".
///
/// Nơi điều hướng truyền nút này vào màn hình chính, nhờ vậy feature notes
/// không phải import feature subjects.
class OpenClassificationButton extends StatelessWidget {
  const OpenClassificationButton({
    required this.subjectRepository,
    required this.noteClassificationRepository,
    super.key,
  });

  final SubjectRepository subjectRepository;
  final NoteClassificationRepository noteClassificationRepository;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey<String>('open-classification'),
      tooltip: 'Phân loại theo môn học và tag',
      icon: const Icon(Icons.label_outline),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider<SubjectsCubit>(
            create: (_) =>
                SubjectsCubit(subjectRepository, noteClassificationRepository)
                  ..load(),
            child: const ClassifiedNotesPage(),
          ),
        ),
      ),
    );
  }
}
