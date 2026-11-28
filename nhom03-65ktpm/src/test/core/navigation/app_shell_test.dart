import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/core/navigation/app_shell.dart';
import 'package:smart_note/core/theme/app_theme.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late AppDependencies dependencies;

  setUp(() {
    authRepository = FakeAuthRepository();
    dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
    );
  });

  tearDown(() => authRepository.dispose());

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<NotesCubit>(
          create: (_) => NotesCubit(dependencies.noteRepository)..load(),
          child: AppShell(notesDependencies: dependencies),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeShell(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(dependencies.dispose);
  }

  testWidgets('Bottom navigation có đúng 4 tab theo thứ tự đã chốt', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    // Chỉ được có một thanh điều hướng: tab Ghi chú không lồng thanh riêng.
    expect(find.byType(NavigationBar), findsOneWidget);
    final Finder outerBar = find.byType(NavigationBar);
    expect(
      find.descendant(
        of: outerBar,
        matching: find.byType(NavigationDestination),
      ),
      findsNWidgets(4),
    );
    for (final String label in <String>[
      'Ghi chú',
      'Nhật ký',
      'Thống kê',
      'Cài đặt',
    ]) {
      expect(
        find.descendant(of: outerBar, matching: find.text(label)),
        findsWidgets,
        reason: 'Thiếu tab $label',
      );
    }

    await disposeShell(tester);
  });

  testWidgets('Mặc định mở tab Ghi chú', (WidgetTester tester) async {
    await pumpShell(tester);

    final NavigationBar bar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(bar.selectedIndex, 0);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

    await disposeShell(tester);
  });

  testWidgets('Chuyển sang tab chưa có màn thì thấy trạng thái sắp ra mắt', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Nhật ký').last);
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(find.text('Sắp ra mắt'), findsWidgets);
    expect(find.text('Tính năng đang được xây dựng'), findsWidgets);

    await disposeShell(tester);
  });

  testWidgets(
    'Tab Cài đặt cũng là màn giữ chỗ, quay lại Ghi chú vẫn giữ dữ liệu',
    (WidgetTester tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Cài đặt').last);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);

      // Nhãn trên NavigationBar nằm sau các trang trong cây widget, nên `.last`
      // là nhãn tab cần bấm.
      await tester.tap(find.text('Ghi chú').last);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
      expect(find.text('Chưa có ghi chú nào'), findsOneWidget);

      await disposeShell(tester);
    },
  );
}
