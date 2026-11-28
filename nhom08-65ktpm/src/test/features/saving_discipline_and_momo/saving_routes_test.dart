import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/routes.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';

void main() {
  group('SavingRoutes Contract Tests', () {
    testWidgets('GoRouter renders all encapsulated Module 2 routes with query parameters', (tester) async {
      final repo = InMemorySavingRepository(seedDemo: true);
      final router = GoRouter(
        initialLocation: SavingRoutes.momoFund,
        routes: savingModuleRoutes(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Quỹ MoMo'), findsOneWidget);

      router.go('${SavingRoutes.savingPlan}?tripId=trip_custom&memberId=m9&memberName=Bình');
      await tester.pumpAndSettle();
      expect(find.text('Kế hoạch Tích góp Định kỳ'), findsOneWidget);

      router.go('${SavingRoutes.pendingReceipts}?tripId=trip_demo_01&memberId=member_demo_01');
      await tester.pumpAndSettle();
      expect(find.textContaining('Duyệt biên lai'), findsOneWidget);

      router.go('${SavingRoutes.streakCalendar}?tripId=trip_demo_01&memberId=member_demo_01');
      await tester.pumpAndSettle();
      expect(find.text('Lịch chuỗi kỷ luật'), findsOneWidget);

      router.go('${SavingRoutes.momoConfig}?tripId=trip_demo_01&memberId=member_demo_01');
      await tester.pumpAndSettle();
      expect(find.text('Thiết lập Quỹ MoMo'), findsOneWidget);

      router.go('${SavingRoutes.momoDeposit}?tripId=trip_demo_01&memberId=member_demo_01');
      await tester.pumpAndSettle();
      expect(find.text('Gửi Trưởng nhóm xác nhận'), findsOneWidget);
    });
  });
}
