import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthylife/app/app.dart';

void main() {
  testWidgets(
    'Startup waits for backend initialization before showing the app',
    (tester) async {
      final startup = Completer<void>();
      await tester.pumpWidget(HealthyLifeApp(initialize: () => startup.future));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cùng xây dựng lối sống lành mạnh.'), findsNothing);

      startup.complete();
      await tester.pumpAndSettle();
      expect(find.text('Cùng xây dựng lối sống lành mạnh.'), findsOneWidget);
    },
  );

  testWidgets(
    'Startup failure can be retried without exposing backend errors',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        HealthyLifeApp(
          initialize: () async {
            if (attempts++ == 0) throw StateError('Internal backend error');
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Không thể khởi động. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.textContaining('Internal backend error'), findsNothing);

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('Cùng xây dựng lối sống lành mạnh.'), findsOneWidget);
    },
  );
}
