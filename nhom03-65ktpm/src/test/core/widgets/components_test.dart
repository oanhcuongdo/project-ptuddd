import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/theme/app_theme.dart';
import 'package:smart_note/core/widgets/confirm_dialog.dart';
import 'package:smart_note/core/widgets/app_password_field.dart';
import 'package:smart_note/core/widgets/app_text_field.dart';
import 'package:smart_note/core/widgets/empty_state.dart';
import 'package:smart_note/core/widgets/tag_chip.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/presentation/widgets/note_card.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('EmptyState hiển thị tiêu đề, mô tả và CTA', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EmptyState(
          icon: Icons.sticky_note_2_outlined,
          title: 'Chưa có ghi chú nào',
          message: 'Ghi chú bạn tạo sẽ xuất hiện tại đây.',
          actionLabel: 'Tạo ghi chú',
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Chưa có ghi chú nào'), findsOneWidget);
    expect(find.text('Ghi chú bạn tạo sẽ xuất hiện tại đây.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Tạo ghi chú'));
    expect(tapped, isTrue);
  });

  testWidgets('ConfirmDialog trả false khi bấm huỷ', (
    WidgetTester tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context,
                  title: 'Đăng xuất?',
                  message: 'Bạn sẽ cần đăng nhập lại.',
                  confirmLabel: 'Đăng xuất',
                  isDestructive: true,
                );
              },
              child: const Text('Mở'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng xuất?'), findsOneWidget);

    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('AppTextField hiển thị nhãn trên ô và lỗi kiểm tra dữ liệu', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _wrap(
        Form(
          key: formKey,
          child: AppTextField(
            label: 'Email',
            hintText: 'ban@truong.edu.vn',
            validator: (String? value) =>
                (value ?? '').isEmpty ? 'Vui lòng nhập email.' : null,
          ),
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('ban@truong.edu.vn'), findsOneWidget);

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
  });

  testWidgets('AppPasswordField ẩn mật khẩu và bật/tắt được', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppPasswordField(label: 'Mật khẩu')));

    bool obscured() =>
        tester.widget<EditableText>(find.byType(EditableText)).obscureText;

    expect(obscured(), isTrue);

    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(obscured(), isFalse);
  });

  testWidgets('NoteCard hiển thị tiêu đề, xem trước và tag', (
    WidgetTester tester,
  ) async {
    final note = Note(
      id: '1',
      title: 'Ghi chú môn Giải tích',
      content: 'Chương 1: giới hạn và liên tục.',
      kind: NoteKind.note,
      createdAt: DateTime(2026, 11, 22, 8),
      updatedAt: DateTime(2026, 11, 22, 9, 30),
      tags: const <String>['Toán'],
    );

    await tester.pumpWidget(_wrap(NoteCard(note: note)));

    expect(find.text('Ghi chú môn Giải tích'), findsOneWidget);
    expect(find.text('Chương 1: giới hạn và liên tục.'), findsOneWidget);
    expect(find.byType(TagChip), findsOneWidget);
    expect(find.text('Toán'), findsOneWidget);
  });

  testWidgets('NoteCard đang chọn thì hiện dấu tick và nhận nhấn giữ', (
    WidgetTester tester,
  ) async {
    var longPressed = false;
    final note = Note(
      id: '2',
      title: 'Vật lý – Điện từ',
      content: 'Định luật Faraday.',
      kind: NoteKind.note,
      createdAt: DateTime(2026, 11, 22, 8),
      updatedAt: DateTime(2026, 11, 22, 9),
    );

    await tester.pumpWidget(
      _wrap(
        NoteCard(
          note: note,
          selected: true,
          onLongPress: () => longPressed = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.longPress(find.text('Vật lý – Điện từ'));
    expect(longPressed, isTrue);
  });
}
