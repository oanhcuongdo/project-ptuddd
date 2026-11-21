import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/app.dart';
import 'package:smart_note/core/di/app_dependencies.dart';

void main() {
  testWidgets(
    'SmartNote hiển thị tiêu đề và trạng thái rỗng khi chưa có ghi chú',
    (WidgetTester tester) async {
      final dependencies = AppDependencies.create(
        executor: NativeDatabase.memory(),
      );

      await tester.pumpWidget(SmartNoteApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      expect(find.text('SmartNote'), findsOneWidget);
      expect(find.text('Chưa có ghi chú nào'), findsOneWidget);

      // Gỡ widget để BlocProvider đóng NotesCubit (huỷ subscription) rồi đóng
      // database, tránh lỗi "Timer is still pending" khi test kết thúc.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(dependencies.dispose);
    },
  );
}
