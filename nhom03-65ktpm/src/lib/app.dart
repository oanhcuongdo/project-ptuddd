import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/app_dependencies.dart';
import 'core/theme/app_theme.dart';
import 'features/notes/presentation/bloc/notes_cubit.dart';
import 'features/notes/presentation/pages/notes_page.dart';

/// Widget gốc của SmartNote.
class SmartNoteApp extends StatelessWidget {
  const SmartNoteApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: BlocProvider<NotesCubit>(
        create: (BuildContext context) =>
            NotesCubit(dependencies.noteRepository)..load(),
        child: const NotesPage(),
      ),
    );
  }
}
