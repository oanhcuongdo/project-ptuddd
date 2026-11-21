import 'package:flutter/material.dart';

import 'core/backend.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthyLifeApp());
}

class HealthyLifeApp extends StatefulWidget {
  const HealthyLifeApp({super.key});

  @override
  State<HealthyLifeApp> createState() => _HealthyLifeAppState();
}

class _HealthyLifeAppState extends State<HealthyLifeApp> {
  late Future<AuthRepository?> _startup = _start();

  Future<AuthRepository?> _start() async {
    try {
      return await initializeBackend();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthyLife',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff216a52)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: FutureBuilder<AuthRepository?>(
        future: _startup,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data case final auth?) return AuthGate(auth: auth);

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không thể khởi động HealthyLife.'),
                    TextButton(
                      onPressed: () => setState(() => _startup = _start()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
