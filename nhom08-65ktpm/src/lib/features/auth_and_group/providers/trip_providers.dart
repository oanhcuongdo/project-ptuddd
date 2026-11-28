import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/trip_member.dart';
import '../../../models/trip_model.dart';
import '../repository/auth_repository.dart';
import '../repository/trip_repository.dart';
import 'auth_providers.dart';

/// Streams all trips that the currently signed-in user belongs to.
final tripListProvider = StreamProvider<List<TripModel>>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser == null) return Stream<List<TripModel>>.value(const []);
  return ref.watch(tripRepositoryProvider).watchUserTrips(authUser.uid);
});

/// Stores the active `tripId` selected by the user.
final selectedTripIdProvider =
    NotifierProvider<SelectedTripIdNotifier, String?>(SelectedTripIdNotifier.new);

class SelectedTripIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? tripId) => state = tripId;
}

/// Resolves the active `tripId` (selected trip or first available trip).
final currentTripIdProvider = Provider<String?>((ref) {
  final selectedId = ref.watch(selectedTripIdProvider);
  if (selectedId != null && selectedId.isNotEmpty) return selectedId;
  final trips = ref.watch(tripListProvider).asData?.value ?? const <TripModel>[];
  return trips.isEmpty ? null : trips.first.id;
});

/// Streams the active [TripModel] based on [currentTripIdProvider].
final currentTripProvider = StreamProvider<TripModel?>((ref) {
  final tripId = ref.watch(currentTripIdProvider);
  if (tripId == null) return Stream<TripModel?>.value(null);
  return ref.watch(tripRepositoryProvider).watchTrip(tripId);
});

/// Streams members of the active trip.
final currentTripMembersProvider = StreamProvider<List<TripMember>>((ref) {
  final tripId = ref.watch(currentTripIdProvider);
  if (tripId == null) return Stream<List<TripMember>>.value(const []);
  return ref.watch(tripRepositoryProvider).watchTripMembers(tripId);
});

/// Handles Trip creation and QR invite joining mutations.
final tripControllerProvider =
    AsyncNotifierProvider<TripController, void>(TripController.new);

class TripController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<TripModel?> createTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int targetBudget,
    TripType tripType = TripType.other,
    String savingFrequency = 'weekly',
    Uint8List? coverImageBytes,
    String? customInviteCode,
  }) async {
    final user =
        ref.read(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = AsyncError(
        const AuthFailure('Vui lòng đăng nhập trước khi tạo chuyến đi.'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();
    TripModel? created;
    state = await AsyncValue.guard(() async {
      created = await ref.read(tripRepositoryProvider).createTrip(
            host: user,
            title: title,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            targetBudget: targetBudget,
            tripType: tripType,
            savingFrequency: savingFrequency,
            coverImageBytes: coverImageBytes,
            customInviteCode: customInviteCode,
          );
    });

    if (created != null) {
      ref.read(selectedTripIdProvider.notifier).select(created!.id);
    }
    return created;
  }

  Future<TripModel?> joinByCode(String rawCode) async {
    final user =
        ref.read(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = AsyncError(
        const AuthFailure('Vui lòng đăng nhập trước khi tham gia nhóm.'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();
    TripModel? joined;
    state = await AsyncValue.guard(() async {
      joined = await ref.read(tripRepositoryProvider).joinTripByCode(
            rawCode: rawCode,
            user: user,
          );
    });

    if (joined != null) {
      ref.read(selectedTripIdProvider.notifier).select(joined!.id);
    }
    return joined;
  }
}
