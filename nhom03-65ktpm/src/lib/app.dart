import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/app_dependencies.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/pages/auth_gate.dart';

/// Widget gốc của SmartNote.
class SmartNoteApp extends StatelessWidget {
  const SmartNoteApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    // AuthCubit được provide **trên** MaterialApp để mọi route (kể cả route
    // được push sau này như màn đăng ký) đều đọc được; nếu đặt bên trong
    // `home:` thì route mới sẽ không thấy provider.
    return BlocProvider<AuthCubit>(
      create: (BuildContext context) =>
          AuthCubit(dependencies.authRepository)..start(),
      child: MaterialApp(
        title: 'SmartNote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: AuthGate(dependencies: dependencies),
      ),
    );
  }
}
