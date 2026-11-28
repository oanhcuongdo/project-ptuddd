import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_storage_service.dart';
import '../../../models/trip_model.dart';
import '../data/smart_templates.dart';
import '../models/checklist_item.dart';

abstract class ChecklistRepository {
  Stream<List<ChecklistItem>> watchTripChecklist(
    String tripId, {
    required String currentUserId,
  });

  Future<ChecklistItem> addItem(ChecklistItem item);

  Future<void> toggleItemCompletion({
    required ChecklistItem item,
    required String completedBy,
  });

  Future<void> assignMember({
    required ChecklistItem item,
    String? assigneeId,
    String? assigneeName,
  });

  Future<ChecklistItem> attachProofPhoto({
    required ChecklistItem item,
    required Uint8List imageBytes,
    required String completedBy,
  });

  Future<void> deleteItem(ChecklistItem item);

  Future<int> applyTemplate({
    required TripModel trip,
    required ChecklistTemplate template,
    required String createdBy,
  });

  Future<List<ChecklistTemplate>> getTemplates();
}

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return InMemoryChecklistRepository();
  }
  return FirestoreChecklistRepository(
    firestore: FirebaseFirestore.instance,
    storageService: ref.watch(supabaseStorageServiceProvider),
  );
});

class FirestoreChecklistRepository implements ChecklistRepository {
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storageService;

  FirestoreChecklistRepository({
    FirebaseFirestore? firestore,
    SupabaseStorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? SupabaseStorageService();

  DocumentReference<Map<String, dynamic>> _tripDoc(String tripId) =>
      _firestore.collection('trips').doc(tripId);

  CollectionReference<Map<String, dynamic>> _checklistsColl(String tripId) =>
      _tripDoc(tripId).collection('checklists');

  @override
  Stream<List<ChecklistItem>> watchTripChecklist(
    String tripId, {
    required String currentUserId,
  }) {
    final controller = StreamController<List<ChecklistItem>>();
    List<ChecklistItem> groupItems = const [];
    List<ChecklistItem> personalItems = const [];
    var hasGroup = false;
    var hasPersonal = currentUserId.isEmpty;

    void emit() {
      if (!hasGroup || !hasPersonal || controller.isClosed) return;
      final merged = [...groupItems, ...personalItems]
        ..sort((a, b) {
          final orderCmp = a.sortOrder.compareTo(b.sortOrder);
          if (orderCmp != 0) return orderCmp;
          return a.createdAt.compareTo(b.createdAt);
        });
      controller.add(merged);
    }

    // Separate scoped queries satisfy Firestore security rules (`scope == 'group'` vs `ownerId == uid`).
    // Sorting is performed in Dart inside `emit()` to avoid composite index build delays.
    final groupSub = _checklistsColl(tripId)
        .where('scope', isEqualTo: 'group')
        .snapshots()
        .listen(
          (snap) {
            groupItems = snap.docs
                .map((d) => ChecklistItem.fromJson({...d.data(), 'id': d.id}))
                .toList();
            hasGroup = true;
            emit();
          },
          onError: controller.addError,
        );

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? personalSub;
    if (currentUserId.isNotEmpty) {
      personalSub = _checklistsColl(tripId)
          .where('scope', isEqualTo: 'personal')
          .where('ownerId', isEqualTo: currentUserId)
          .snapshots()
          .listen(
            (snap) {
              personalItems = snap.docs
                  .map((d) => ChecklistItem.fromJson({...d.data(), 'id': d.id}))
                  .toList();
              hasPersonal = true;
              emit();
            },
            onError: controller.addError,
          );
    }

    controller.onCancel = () async {
      await groupSub.cancel();
      await personalSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<ChecklistItem> addItem(ChecklistItem item) async {
    final coll = _checklistsColl(item.tripId);
    final docRef = item.id.isEmpty ? coll.doc() : coll.doc(item.id);
    final saved = item.copyWith(
      id: docRef.id,
      ownerId: item.scope == ChecklistScope.personal
          ? (item.ownerId ?? item.createdBy)
          : item.ownerId,
    );

    final batch = _firestore.batch();
    batch.set(docRef, saved.toJson());
    if (saved.scope == ChecklistScope.group) {
      batch.update(_tripDoc(saved.tripId), {
        'checklistTotal': FieldValue.increment(1),
        if (saved.isCompleted) 'checklistCompleted': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
    return saved;
  }

  @override
  Future<void> toggleItemCompletion({
    required ChecklistItem item,
    required String completedBy,
  }) async {
    final itemRef = _checklistsColl(item.tripId).doc(item.id);
    final tripRef = _tripDoc(item.tripId);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(itemRef);
      if (!snap.exists || snap.data() == null) return;
      final current = ChecklistItem.fromJson({...snap.data()!, 'id': snap.id});
      final nextCompleted = !current.isCompleted;
      final now = Timestamp.now();

      transaction.update(itemRef, {
        'isCompleted': nextCompleted,
        'completedAt': nextCompleted ? now : null,
        'completedBy': nextCompleted ? completedBy : null,
      });

      if (current.scope == ChecklistScope.group) {
        transaction.update(tripRef, {
          'checklistCompleted': FieldValue.increment(nextCompleted ? 1 : -1),
          'updatedAt': now,
        });
      }
    });
  }

  @override
  Future<void> assignMember({
    required ChecklistItem item,
    String? assigneeId,
    String? assigneeName,
  }) async {
    await _checklistsColl(item.tripId).doc(item.id).update({
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
    });
  }

  @override
  Future<ChecklistItem> attachProofPhoto({
    required ChecklistItem item,
    required Uint8List imageBytes,
    required String completedBy,
  }) async {
    final now = DateTime.now();
    final storagePath =
        'trips/${item.tripId}/checklists/${item.id}/${now.millisecondsSinceEpoch}.jpg';
    final url = await _storageService.uploadBytes(
      path: storagePath,
      bytes: imageBytes,
    );

    final oldStoragePath = item.proofStoragePath;
    final itemRef = _checklistsColl(item.tripId).doc(item.id);
    final tripRef = _tripDoc(item.tripId);

    final updated = await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(itemRef);
      final current = (snap.exists && snap.data() != null)
          ? ChecklistItem.fromJson({...snap.data()!, 'id': snap.id})
          : item;
      final becameCompleted = !current.isCompleted;

      final nextItem = current.copyWith(
        isCompleted: true,
        completedAt: current.completedAt ?? now,
        completedBy: current.completedBy ?? completedBy,
        proofImageUrl: url,
        proofStoragePath: storagePath,
      );

      transaction.update(itemRef, {
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(nextItem.completedAt!),
        'completedBy': nextItem.completedBy,
        'proofImageUrl': url,
        'proofStoragePath': storagePath,
      });

      if (becameCompleted && current.scope == ChecklistScope.group) {
        transaction.update(tripRef, {
          'checklistCompleted': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
      }
      return nextItem;
    });

    if (oldStoragePath != null &&
        oldStoragePath.isNotEmpty &&
        oldStoragePath != storagePath) {
      try {
        await _storageService.deleteFile(oldStoragePath);
      } catch (_) {}
    }

    return updated;
  }

  @override
  Future<void> deleteItem(ChecklistItem item) async {
    final batch = _firestore.batch();
    batch.delete(_checklistsColl(item.tripId).doc(item.id));
    if (item.scope == ChecklistScope.group) {
      batch.update(_tripDoc(item.tripId), {
        'checklistTotal': FieldValue.increment(-1),
        if (item.isCompleted) 'checklistCompleted': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();

    if (item.proofStoragePath != null && item.proofStoragePath!.isNotEmpty) {
      try {
        await _storageService.deleteFile(item.proofStoragePath!);
      } catch (_) {}
    }
  }

  @override
  Future<int> applyTemplate({
    required TripModel trip,
    required ChecklistTemplate template,
    required String createdBy,
  }) async {
    final existingGroup = await _checklistsColl(trip.id)
        .where('scope', isEqualTo: 'group')
        .get();
    final existingPersonal = await _checklistsColl(trip.id)
        .where('scope', isEqualTo: 'personal')
        .where('ownerId', isEqualTo: createdBy)
        .get();

    final existingTitles = <String>{
      ...existingGroup.docs.map((d) => (d.data()['title'] as String? ?? '').toLowerCase()),
      ...existingPersonal.docs.map((d) => (d.data()['title'] as String? ?? '').toLowerCase()),
    };

    final now = DateTime.now();
    var nextOrder = existingGroup.docs.length + existingPersonal.docs.length;
    var addedCount = 0;
    var groupAddedCount = 0;

    final batch = _firestore.batch();
    for (final tplItem in template.items) {
      if (existingTitles.contains(tplItem.title.toLowerCase())) continue;

      final daysBefore =
          tplItem.daysBeforeDeparture ?? tplItem.phase.defaultDaysBeforeDeparture;
      final dueDate = trip.startDate.subtract(Duration(days: daysBefore));
      final docRef = _checklistsColl(trip.id).doc();

      final newItem = ChecklistItem(
        id: docRef.id,
        tripId: trip.id,
        title: tplItem.title,
        phase: tplItem.phase,
        scope: tplItem.scope,
        ownerId: tplItem.scope == ChecklistScope.personal ? createdBy : null,
        dueDate: dueDate,
        sortOrder: nextOrder++,
        createdBy: createdBy,
        createdAt: now,
      );
      batch.set(docRef, newItem.toJson());
      addedCount++;
      if (newItem.scope == ChecklistScope.group) {
        groupAddedCount++;
      }
    }

    if (addedCount == 0) return 0;

    if (groupAddedCount > 0) {
      batch.update(_tripDoc(trip.id), {
        'checklistTotal': FieldValue.increment(groupAddedCount),
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
    return addedCount;
  }

  @override
  Future<List<ChecklistTemplate>> getTemplates() async {
    try {
      final snap = await _firestore.collection('checklist_templates').get();
      if (snap.docs.isEmpty) return SmartChecklistTemplates.all;
      return snap.docs.map((d) {
        final data = d.data();
        final rawItems = (data['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ChecklistTemplateItem.fromMap)
            .toList();
        return ChecklistTemplate(
          id: d.id,
          tripType: data['tripType'] as String? ?? 'other',
          name: data['name'] as String? ?? d.id,
          subtitle: data['subtitle'] as String? ?? '${rawItems.length} đầu việc mẫu',
          items: rawItems,
        );
      }).toList();
    } catch (_) {
      return SmartChecklistTemplates.all;
    }
  }
}

/// Offline/preview fallback repository used when Firebase is not initialized.
class InMemoryChecklistRepository implements ChecklistRepository {
  final _controller = StreamController<List<ChecklistItem>>.broadcast();
  final Map<String, List<ChecklistItem>> _store = {};

  InMemoryChecklistRepository({bool seedDemo = true}) {
    if (seedDemo) {
      final now = DateTime.now();
      _store['demo-trip'] = [
        ChecklistItem(
          id: 'chk-1',
          tripId: 'demo-trip',
          title: 'Đặt vé xe giường nằm khứ hồi',
          phase: ChecklistPhase.before30d,
          scope: ChecklistScope.group,
          assigneeId: 'demo-host-an',
          assigneeName: 'Đỗ Đình An',
          dueDate: now.add(const Duration(days: 1)),
          isCompleted: true,
          completedAt: now.subtract(const Duration(days: 1)),
          completedBy: 'demo-host-an',
          proofImageUrl: 'https://demo.supabase.co/storage/v1/object/public/travel-buddy/demo/ticket.jpg',
          sortOrder: 0,
          createdBy: 'demo-host-an',
          createdAt: now,
        ),
        ChecklistItem(
          id: 'chk-2',
          tripId: 'demo-trip',
          title: 'Đặt cọc homestay view đồi thông',
          phase: ChecklistPhase.before30d,
          scope: ChecklistScope.group,
          assigneeId: 'demo-member-binh',
          assigneeName: 'Nguyễn Xuân Bình',
          dueDate: now.add(const Duration(days: 2)),
          isCompleted: true,
          completedAt: now,
          completedBy: 'demo-member-binh',
          sortOrder: 1,
          createdBy: 'demo-host-an',
          createdAt: now,
        ),
        ChecklistItem(
          id: 'chk-3',
          tripId: 'demo-trip',
          title: 'Thuê xe máy 4 chiếc tại Đà Lạt',
          phase: ChecklistPhase.before14d,
          scope: ChecklistScope.group,
          dueDate: now.add(const Duration(days: 1)),
          sortOrder: 2,
          createdBy: 'demo-host-an',
          createdAt: now,
        ),
        ChecklistItem(
          id: 'chk-4',
          tripId: 'demo-trip',
          title: 'Mua áo giữ nhiệt & thuốc say xe',
          phase: ChecklistPhase.before14d,
          scope: ChecklistScope.group,
          assigneeId: 'demo-member-khanh',
          assigneeName: 'Đỗ Tùng Khánh',
          dueDate: now.add(const Duration(days: 5)),
          sortOrder: 3,
          createdBy: 'demo-host-an',
          createdAt: now,
        ),
        ChecklistItem(
          id: 'chk-5',
          tripId: 'demo-trip',
          title: 'Sạc dự phòng 20.000mAh & ổ cắm đa năng',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.group,
          assigneeId: 'demo-member-dung',
          assigneeName: 'Hồ Thế Dũng',
          isCompleted: true,
          completedAt: now,
          completedBy: 'demo-member-dung',
          sortOrder: 4,
          createdBy: 'demo-host-an',
          createdAt: now,
        ),
        ChecklistItem(
          id: 'chk-6',
          tripId: 'demo-trip',
          title: 'CCCD/GPLX & áo khoác gió cá nhân',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.personal,
          ownerId: 'demo-host-an',
          dueDate: now.add(const Duration(days: 2)),
          sortOrder: 5,
          createdBy: 'demo-host-an',
          createdAt: now,
        ),
      ];
    }
  }

  List<ChecklistItem> _filterForUser(String tripId, String currentUserId) {
    final all = _store[tripId] ?? const [];
    return all
        .where(
          (item) =>
              item.scope == ChecklistScope.group ||
              item.ownerId == currentUserId,
        )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  void _notify() {
    _controller.add(_store.values.expand((e) => e).toList());
  }

  @override
  Stream<List<ChecklistItem>> watchTripChecklist(
    String tripId, {
    required String currentUserId,
  }) async* {
    yield _filterForUser(tripId, currentUserId);
    await for (final _ in _controller.stream) {
      yield _filterForUser(tripId, currentUserId);
    }
  }

  @override
  Future<ChecklistItem> addItem(ChecklistItem item) async {
    final id = item.id.isEmpty
        ? 'chk-${DateTime.now().millisecondsSinceEpoch}'
        : item.id;
    final saved = item.copyWith(
      id: id,
      ownerId: item.scope == ChecklistScope.personal
          ? (item.ownerId ?? item.createdBy)
          : item.ownerId,
    );
    _store.putIfAbsent(saved.tripId, () => []).add(saved);
    _notify();
    return saved;
  }

  @override
  Future<void> toggleItemCompletion({
    required ChecklistItem item,
    required String completedBy,
  }) async {
    final list = _store[item.tripId];
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx < 0) return;
    final cur = list[idx];
    final next = !cur.isCompleted;
    list[idx] = cur.copyWith(
      isCompleted: next,
      completedAt: next ? DateTime.now() : null,
      completedBy: next ? completedBy : null,
    );
    _notify();
  }

  @override
  Future<void> assignMember({
    required ChecklistItem item,
    String? assigneeId,
    String? assigneeName,
  }) async {
    final list = _store[item.tripId];
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(
      assigneeId: assigneeId,
      assigneeName: assigneeName,
    );
    _notify();
  }

  @override
  Future<ChecklistItem> attachProofPhoto({
    required ChecklistItem item,
    required Uint8List imageBytes,
    required String completedBy,
  }) async {
    final list = _store[item.tripId];
    final now = DateTime.now();
    final updated = item.copyWith(
      isCompleted: true,
      completedAt: item.completedAt ?? now,
      completedBy: item.completedBy ?? completedBy,
      proofImageUrl:
          'https://demo.supabase.co/storage/v1/object/public/travel-buddy/trips/${item.tripId}/checklists/${item.id}/${now.millisecondsSinceEpoch}.jpg',
      proofStoragePath:
          'trips/${item.tripId}/checklists/${item.id}/${now.millisecondsSinceEpoch}.jpg',
    );
    if (list != null) {
      final idx = list.indexWhere((e) => e.id == item.id);
      if (idx >= 0) list[idx] = updated;
    }
    _notify();
    return updated;
  }

  @override
  Future<void> deleteItem(ChecklistItem item) async {
    _store[item.tripId]?.removeWhere((e) => e.id == item.id);
    _notify();
  }

  @override
  Future<int> applyTemplate({
    required TripModel trip,
    required ChecklistTemplate template,
    required String createdBy,
  }) async {
    final list = _store.putIfAbsent(trip.id, () => []);
    final existingTitles = list.map((e) => e.title.toLowerCase()).toSet();
    final now = DateTime.now();
    var nextOrder = list.length;
    var added = 0;

    for (final tplItem in template.items) {
      if (existingTitles.contains(tplItem.title.toLowerCase())) continue;
      final daysBefore =
          tplItem.daysBeforeDeparture ?? tplItem.phase.defaultDaysBeforeDeparture;
      list.add(
        ChecklistItem(
          id: 'chk-${now.millisecondsSinceEpoch}-$nextOrder',
          tripId: trip.id,
          title: tplItem.title,
          phase: tplItem.phase,
          scope: tplItem.scope,
          ownerId: tplItem.scope == ChecklistScope.personal ? createdBy : null,
          dueDate: trip.startDate.subtract(Duration(days: daysBefore)),
          sortOrder: nextOrder++,
          createdBy: createdBy,
          createdAt: now,
        ),
      );
      added++;
    }
    if (added > 0) _notify();
    return added;
  }

  @override
  Future<List<ChecklistTemplate>> getTemplates() async =>
      SmartChecklistTemplates.all;
}
