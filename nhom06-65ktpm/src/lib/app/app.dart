import 'package:flutter/material.dart';

import '../core/backend.dart';

class HealthyLifeApp extends StatefulWidget {
  const HealthyLifeApp({super.key, this.initialize = initializeBackend});

  final Future<void> Function() initialize;

  @override
  State<HealthyLifeApp> createState() => _HealthyLifeAppState();
}

class _HealthyLifeAppState extends State<HealthyLifeApp> {
  late Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = widget.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthyLife',
      home: Scaffold(
        appBar: AppBar(title: const Text('HealthyLife')),
        body: Center(
          child: FutureBuilder<void>(
            future: _startup,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator(
                  semanticsLabel: 'Đang khởi động',
                );
              }
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không thể khởi động. Vui lòng thử lại.'),
                    FilledButton(
                      onPressed: () => setState(() {
                        _startup = widget.initialize();
                      }),
                      child: const Text('Thử lại'),
                    ),
                  ],
                );
              }
              return const Text('Cùng xây dựng lối sống lành mạnh.');
            },
          ),
        ),
      ),
    );
  }
}
