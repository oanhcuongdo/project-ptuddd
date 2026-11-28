import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/auth_and_group/repository/auth_repository.dart';
import 'package:travel_buddy/main.dart';

void main() {
  testWidgets('TravelBuddyApp redirects to TripListScreen when signed in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TravelBuddyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chuyến đi'), findsOneWidget);
    expect(find.text('Đà Lạt 4N3Đ'), findsOneWidget);
  });

  testWidgets('TravelBuddyApp stays on LoginScreen when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            InMemoryAuthRepository(seedSignedIn: false),
          ),
        ],
        child: const TravelBuddyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Travel Buddy'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
