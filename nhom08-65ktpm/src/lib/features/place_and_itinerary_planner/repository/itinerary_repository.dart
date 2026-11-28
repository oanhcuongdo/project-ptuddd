import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../models/place_plan.dart';

abstract class ItineraryRepository {
  Stream<List<PlacePlan>> watchPlans(String tripId);
  Future<void> savePlan(PlacePlan plan);
  Future<void> deletePlan(String tripId, String planId);
  Future<void> reorderPlans(
    String tripId,
    int dayNumber,
    List<PlacePlan> plans,
  );
  Future<PlacePlan> checkIn(PlacePlan plan, XFile image);
}

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  if (Firebase.apps.isEmpty) return InMemoryItineraryRepository();
  return FirestoreItineraryRepository(
    FirebaseFirestore.instance,
    ref.watch(supabaseStorageServiceProvider),
  );
});

class FirestoreItineraryRepository implements ItineraryRepository {
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storageService;
  FirestoreItineraryRepository(this._firestore, this._storageService);

  DocumentReference<Map<String, dynamic>> _tripDoc(String tripId) =>
      _firestore.collection('trips').doc(tripId);

  CollectionReference<Map<String, dynamic>> _collection(String tripId) =>
      _tripDoc(tripId).collection('place_plans');

  @override
  Stream<List<PlacePlan>> watchPlans(String tripId) => _collection(tripId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => PlacePlan.fromMap(doc.data(), id: doc.id))
            .toList()
          ..sort((a, b) {
            final dayCmp = a.dayNumber.compareTo(b.dayNumber);
            if (dayCmp != 0) return dayCmp;
            return a.sortOrder.compareTo(b.sortOrder);
          }),
      );

  @override
  Future<void> savePlan(PlacePlan plan) async {
    await _collection(
      plan.tripId,
    ).doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
    await _syncTotalPlannedCost(plan.tripId);
  }

  @override
  Future<void> deletePlan(String tripId, String planId) async {
    await _collection(tripId).doc(planId).delete();
    await _syncTotalPlannedCost(tripId);
  }

  Future<void> _syncTotalPlannedCost(String tripId) async {
    try {
      final snap = await _collection(tripId).get();
      final total = snap.docs.fold<double>(0.0, (sum, doc) {
        final plan = PlacePlan.fromMap(doc.data(), id: doc.id);
        return sum + plan.totalEstimatedCost;
      });
      await _tripDoc(tripId).update({
        'totalPlannedItineraryCost': total.round(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Sync totalPlannedItineraryCost skipped: $e');
    }
  }

  @override
  Future<void> reorderPlans(
    String tripId,
    int dayNumber,
    List<PlacePlan> plans,
  ) async {
    final batch = _firestore.batch();
    for (var i = 0; i < plans.length; i++) {
      batch.update(_collection(tripId).doc(plans[i].id), {
        'sortOrder': i,
        'dayNumber': dayNumber,
      });
    }
    await batch.commit();
  }

  @override
  Future<PlacePlan> checkIn(PlacePlan plan, XFile image) async {
    final photoUrl = await _storageService.uploadBytes(
      path: 'trips/${plan.tripId}/checkins/${plan.id}.jpg',
      bytes: await image.readAsBytes(),
    );
    final updated = plan.copyWith(
      isCheckedIn: true,
      checkedInAt: DateTime.now(),
      checkInPhotoUrl: photoUrl,
    );
    await savePlan(updated);
    return updated;
  }
}

class InMemoryItineraryRepository implements ItineraryRepository {
  final _data = <String, List<PlacePlan>>{};
  final _controllers = <String, StreamController<List<PlacePlan>>>{};

  void _notify(String tripId) {
    final ctrl = _controllers[tripId];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(List.unmodifiable(_data[tripId] ?? const []));
    }
  }

  @override
  Stream<List<PlacePlan>> watchPlans(String tripId) {
    final ctrl = _controllers.putIfAbsent(
      tripId,
      () => StreamController<List<PlacePlan>>.broadcast(),
    );
    late final StreamController<List<PlacePlan>> wrapper;
    StreamSubscription<List<PlacePlan>>? sub;
    wrapper = StreamController<List<PlacePlan>>(
      onListen: () {
        wrapper.add(List.unmodifiable(_data[tripId] ?? const []));
        sub = ctrl.stream.listen(
          wrapper.add,
          onError: wrapper.addError,
        );
      },
      onCancel: () async {
        await sub?.cancel();
        await wrapper.close();
      },
    );
    return wrapper.stream;
  }

  @override
  Future<void> savePlan(PlacePlan plan) async {
    final list = _data.putIfAbsent(plan.tripId, () => []);
    final index = list.indexWhere((item) => item.id == plan.id);
    if (index < 0) {
      list.add(plan);
    } else {
      list[index] = plan;
    }
    _notify(plan.tripId);
  }

  @override
  Future<void> deletePlan(String tripId, String planId) async {
    _data[tripId]?.removeWhere((p) => p.id == planId);
    _notify(tripId);
  }

  @override
  Future<void> reorderPlans(
    String tripId,
    int dayNumber,
    List<PlacePlan> plans,
  ) async {
    for (var i = 0; i < plans.length; i++) {
      await savePlan(plans[i].copyWith(sortOrder: i));
    }
  }

  @override
  Future<PlacePlan> checkIn(PlacePlan plan, XFile image) async {
    final updated = plan.copyWith(isCheckedIn: true, checkedInAt: DateTime.now());
    await savePlan(updated);
    return updated;
  }
}
