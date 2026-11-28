import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/place_plan.dart';
import '../models/place_suggestion.dart';
import '../repository/itinerary_repository.dart';
import '../repository/place_discovery_repository.dart';
import '../utils/schedule_conflict_helper.dart';

final placeDiscoveryRepositoryProvider = Provider(
  (ref) => PlaceDiscoveryRepository(),
);
final selectedDayProvider = StateProvider.family<int, String>(
  (ref, tripId) => 1,
);
final suggestionFilterProvider = StateProvider<PlaceCategory?>((ref) => null);
final suggestionQueryProvider = StateProvider<String>((ref) => '');

final itineraryProvider =
    NotifierProvider.family<ItineraryNotifier, ItineraryState, String>(
      ItineraryNotifier.new,
    );

class ItineraryState {
  final List<PlacePlan> plans;
  final List<PlaceSuggestion> suggestions;
  final bool loading;
  final bool usedFallbackSuggestions;
  final String? error;
  const ItineraryState({
    this.plans = const [],
    this.suggestions = const [],
    this.loading = false,
    this.usedFallbackSuggestions = false,
    this.error,
  });
  List<PlacePlan> forDay(int day) =>
      plans.where((p) => p.dayNumber == day).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  List<String> conflicts(int day) => findConflictingPlanIds(forDay(day));
  double dayCost(int day) => totalCost(forDay(day));
  double get tripCost => totalCost(plans);
}

class ItineraryNotifier extends Notifier<ItineraryState> {
  final String tripId;
  ItineraryNotifier(this.tripId);
  late final ItineraryRepository _repository;
  StreamSubscription<List<PlacePlan>>? _subscription;

  @override
  ItineraryState build() {
    _repository = ref.watch(itineraryRepositoryProvider);
    _subscription?.cancel();
    _subscription = _repository.watchPlans(tripId).listen(
      (plans) {
        state = ItineraryState(
          plans: plans,
          suggestions: state.suggestions,
          loading: false,
          usedFallbackSuggestions: state.usedFallbackSuggestions,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        state = ItineraryState(
          plans: state.plans,
          suggestions: state.suggestions,
          loading: false,
          usedFallbackSuggestions: state.usedFallbackSuggestions,
          error: error.toString(),
        );
      },
    );
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return const ItineraryState(loading: true);
  }

  Future<void> save(PlacePlan plan) async {
    await _repository.savePlan(plan);
  }

  Future<void> delete(PlacePlan plan) async {
    await _repository.deletePlan(plan.tripId, plan.id);
  }

  Future<void> reorder(int day, int oldIndex, int newIndex) async {
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    await reorderAdjusted(day, oldIndex, adjustedNew);
  }

  Future<void> reorderAdjusted(int day, int oldIndex, int newIndex) async {
    final list = state.forDay(day);
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex >= list.length) {
      return;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final updated = [
      for (var i = 0; i < list.length; i++) list[i].copyWith(sortOrder: i),
    ];
    await _repository.reorderPlans(tripId, day, updated);
  }

  Future<void> searchSuggestions({
    String query = '',
    PlaceCategory? category,
    double latitude = 16.0544,
    double longitude = 108.2022,
    String? destinationName,
  }) async {
    state = ItineraryState(
      plans: state.plans,
      suggestions: state.suggestions,
      loading: true,
      usedFallbackSuggestions: state.usedFallbackSuggestions,
    );
    try {
      final discovery = ref.read(placeDiscoveryRepositoryProvider);
      final items = await discovery.search(
        query: query,
        category: category,
        latitude: latitude,
        longitude: longitude,
        destinationName: destinationName,
      );
      state = ItineraryState(
        plans: state.plans,
        suggestions: items,
        loading: false,
        usedFallbackSuggestions: discovery.lastSearchUsedFallback,
      );
    } catch (e) {
      state = ItineraryState(
        plans: state.plans,
        suggestions: state.suggestions,
        loading: false,
        usedFallbackSuggestions: true,
        error: e.toString(),
      );
    }
  }
}
