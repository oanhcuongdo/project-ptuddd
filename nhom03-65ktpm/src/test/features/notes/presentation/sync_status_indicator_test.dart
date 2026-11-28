import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/sync/sync_status.dart';
import 'package:smart_note/features/notes/presentation/widgets/sync_status_indicator.dart';

Future<void> pumpIndicator(
  WidgetTester tester,
  SyncStatus status, {
  String? message,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            SyncStatusIndicator(status: status, message: message),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('chưa cấu hình Supabase thì không hiện chỉ báo', (
    WidgetTester tester,
  ) async {
    await pumpIndicator(tester, SyncStatus.disabled);

    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('trạng thái đang đồng bộ có nhãn cho trình đọc màn hình', (
    WidgetTester tester,
  ) async {
    await pumpIndicator(tester, SyncStatus.syncing);

    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Đang đồng bộ'), findsOneWidget);
  });

  testWidgets('trạng thái đã đồng bộ hiện đám mây có dấu kiểm', (
    WidgetTester tester,
  ) async {
    await pumpIndicator(tester, SyncStatus.synced);

    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
  });

  testWidgets('trạng thái lỗi hiện đám mây gạch chéo kèm thông điệp', (
    WidgetTester tester,
  ) async {
    await pumpIndicator(
      tester,
      SyncStatus.error,
      message: 'Không có kết nối mạng',
    );

    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(
      find.byTooltip('Lỗi đồng bộ — Không có kết nối mạng'),
      findsOneWidget,
    );
  });
}
