import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create();
  runApp(SmartNoteApp(dependencies: dependencies));
}
