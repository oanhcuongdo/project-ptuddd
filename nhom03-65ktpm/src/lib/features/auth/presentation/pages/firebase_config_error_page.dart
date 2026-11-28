import 'package:flutter/material.dart';

/// Hiển thị khi Firebase chưa được cấu hình, thay vì để app crash khó hiểu.
class FirebaseConfigErrorPage extends StatelessWidget {
  const FirebaseConfigErrorPage({required this.detail, super.key});

  final String detail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.settings_suggest_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa cấu hình Firebase',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thêm android/app/google-services.json (do flutterfire '
                    'configure sinh ra) hoặc chạy app kèm các --dart-define '
                    'FIREBASE_API_KEY, FIREBASE_APP_ID, '
                    'FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID.',
                  ),
                  const SizedBox(height: 12),
                  Text(detail),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
