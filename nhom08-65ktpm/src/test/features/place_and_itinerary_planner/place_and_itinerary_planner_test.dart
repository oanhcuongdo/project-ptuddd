import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_buddy/features/place_and_itinerary_planner/models/place_plan.dart';
import 'package:travel_buddy/features/place_and_itinerary_planner/providers/itinerary_providers.dart';
import 'package:travel_buddy/features/place_and_itinerary_planner/repository/itinerary_repository.dart';
import 'package:travel_buddy/features/place_and_itinerary_planner/repository/place_discovery_repository.dart';
import 'package:travel_buddy/features/place_and_itinerary_planner/utils/schedule_conflict_helper.dart';

PlacePlan makePlan({
  required String id,
  required int startHour,
  String tripId = 'trip-test',
  int startMinute = 0,
  int durationMinutes = 60,
  int sortOrder = 0,
  PlaceCategory category = PlaceCategory.attraction,
  double ticketCost = 0,
  double foodCost = 0,
}) {
  return PlacePlan(
    id: id,
    tripId: tripId,
    dayNumber: 1,
    sortOrder: sortOrder,
    placeName: 'Địa điểm $id',
    category: category,
    latitude: 10.7769,
    longitude: 106.7009,
    startTime: DateTime(2025, 1, 1, startHour, startMinute),
    durationMinutes: durationMinutes,
    ticketCost: ticketCost,
    foodCost: foodCost,
  );
}

void main() {
  group('PlacePlan and schedule helpers', () {
    test('calculates end time and estimated cost', () {
      final plan = makePlan(
        id: 'museum',
        startHour: 9,
        startMinute: 15,
        durationMinutes: 90,
        ticketCost: 80000,
        foodCost: 120000,
      );

      expect(plan.endTime, DateTime(2025, 1, 1, 10, 45));
      expect(plan.totalEstimatedCost, 200000);
      expect(formatTime(plan.startTime), '09:15');
      expect(formatVnd(plan.totalEstimatedCost), '200.000 đ');
    });

    test('detects overlapping intervals in both plans', () {
      final first = makePlan(id: 'first', startHour: 9, durationMinutes: 120);
      final second = makePlan(id: 'second', startHour: 10, durationMinutes: 60);

      expect(
        findConflictingPlanIds([first, second]),
        containsAll(['first', 'second']),
      );
    });

    test('does not flag plans that touch at the boundary', () {
      final first = makePlan(id: 'first', startHour: 9, durationMinutes: 60);
      final second = makePlan(id: 'second', startHour: 10, durationMinutes: 60);

      expect(findConflictingPlanIds([first, second]), isEmpty);
    });

    test('sums ticket, food and total costs', () {
      final plans = [
        makePlan(id: 'one', startHour: 8, ticketCost: 50000, foodCost: 30000),
        makePlan(id: 'two', startHour: 11, ticketCost: 100000, foodCost: 70000),
      ];

      expect(totalTicketCost(plans), 150000);
      expect(totalFoodCost(plans), 100000);
      expect(totalCost(plans), 250000);
    });

    test('round-trips a plan through Firestore-compatible map data', () {
      final original = makePlan(
        id: 'round-trip',
        startHour: 14,
        durationMinutes: 45,
        category: PlaceCategory.food,
        ticketCost: 10000,
        foodCost: 90000,
      );

      final restored = PlacePlan.fromMap(original.toMap(), id: original.id);

      expect(restored.id, original.id);
      expect(restored.category, PlaceCategory.food);
      expect(restored.startTime, original.startTime);
      expect(restored.durationMinutes, 45);
      expect(restored.totalEstimatedCost, 100000);
    });
  });

  group('InMemoryItineraryRepository', () {
    late InMemoryItineraryRepository repository;

    setUp(() => repository = InMemoryItineraryRepository());

    test('adds and updates a plan without Firebase', () async {
      final original = makePlan(id: 'plan-1', startHour: 9);
      await repository.savePlan(original);
      await repository.savePlan(original.copyWith(placeName: 'Tên mới'));

      final plans = await repository.watchPlans('trip-test').first;

      expect(plans, hasLength(1));
      expect(plans.single.placeName, 'Tên mới');
    });

    test('deletes a plan', () async {
      final plan = makePlan(id: 'delete-me', startHour: 9);
      await repository.savePlan(plan);
      await repository.deletePlan(plan.tripId, plan.id);

      expect(await repository.watchPlans(plan.tripId).first, isEmpty);
    });

    test('reorders plans and updates sortOrder', () async {
      final first = makePlan(id: 'first', startHour: 9, sortOrder: 0);
      final second = makePlan(id: 'second', startHour: 11, sortOrder: 1);
      await repository.savePlan(first);
      await repository.savePlan(second);

      await repository.reorderPlans('trip-test', 1, [second, first]);
      final plans = await repository.watchPlans('trip-test').first;

      expect(plans.firstWhere((plan) => plan.id == 'second').sortOrder, 0);
      expect(plans.firstWhere((plan) => plan.id == 'first').sortOrder, 1);
    });

    test('marks a plan as checked in without Firebase or Storage', () async {
      final plan = makePlan(id: 'check-in', startHour: 9);
      final image = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'test.jpg',
      );

      final checkedIn = await repository.checkIn(plan, image);

      expect(checkedIn.isCheckedIn, isTrue);
      expect(checkedIn.checkedInAt, isNotNull);
      expect(checkedIn.checkInPhotoUrl, isNull);
    });
  });

  group('PlaceDiscoveryRepository fallback', () {
    final repository = PlaceDiscoveryRepository();

    test('returns all three fallback categories', () {
      final suggestions = repository.fallback(null, '');

      expect(
        suggestions.map((item) => item.category),
        containsAll(<PlaceCategory>[
          PlaceCategory.attraction,
          PlaceCategory.food,
          PlaceCategory.hotel,
        ]),
      );
    });

    test('filters fallback suggestions by category', () {
      final suggestions = repository.fallback(PlaceCategory.food, '');

      expect(suggestions, hasLength(1));
      expect(suggestions.single.category, PlaceCategory.food);
    });

    test('filters fallback suggestions by query', () {
      final suggestions = repository.fallback(null, 'bến thành');

      expect(suggestions, hasLength(1));
      expect(suggestions.single.category, PlaceCategory.food);
    });

    test('resolves known Vietnam destination coordinates offline', () async {
      final dalat = await repository.resolveDestinationCoordinates('Đà Lạt, Lâm Đồng');
      expect(dalat, isNotNull);
      expect(dalat!.lat, closeTo(11.9404, 0.01));
      expect(dalat.lon, closeTo(108.4583, 0.01));
    });
  });

  group('ItineraryNotifier realtime stream', () {
    test('updates state automatically on repository save and delete', () async {
      final repo = InMemoryItineraryRepository();
      final container = ProviderContainer(
        overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const tripId = 'trip-stream';
      final sub = container.listen(itineraryProvider(tripId), (_, _) {});
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      expect(container.read(itineraryProvider(tripId)).plans, isEmpty);

      final plan = makePlan(
        id: 'rt-1',
        tripId: tripId,
        startHour: 9,
        ticketCost: 50000,
      );
      await repo.savePlan(plan);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(itineraryProvider(tripId)).plans, hasLength(1));
      expect(container.read(itineraryProvider(tripId)).tripCost, 50000);

      await repo.deletePlan(tripId, 'rt-1');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(itineraryProvider(tripId)).plans, isEmpty);
    });
  });
}
