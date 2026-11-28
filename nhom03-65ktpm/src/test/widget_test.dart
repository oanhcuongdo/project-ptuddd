import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/app.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/features/auth/domain/entities/app_user.dart';
import 'package:smart_note/features/notes/presentation/pages/notes_page.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('Đã có phiên đăng nhập thì vào thẳng màn hình chính', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialUser: const AppUser(id: 'uid-1', email: 'minh@example.com'),
    );
    final dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
    );

    await tester.pumpWidget(SmartNoteApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    // Đã đăng nhập nên vào màn ghi chú (tab đầu của bottom navigation),
    // không hiện màn đăng nhập.
    expect(find.byType(NotesPage), findsOneWidget);
    expect(find.text('Ghi chú'), findsWidgets);
    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsNothing);
    expect(find.text('Chưa có ghi chú nào'), findsOneWidget);

    // Gỡ widget để BlocProvider đóng cubit (huỷ subscription) rồi đóng
    // database, tránh lỗi "Timer is still pending" khi test kết thúc.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(dependencies.dispose);
    await tester.runAsync(authRepository.dispose);
  });
}
