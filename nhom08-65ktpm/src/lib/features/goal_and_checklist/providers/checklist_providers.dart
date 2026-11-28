import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/local_notification_service.dart';
import '../../../models/trip_model.dart';
import '../../auth_and_group/providers/auth_providers.dart';
import '../../auth_and_group/repository/auth_repository.dart';
import '../models/checklist_item.dart';
import '../repository/checklist_repository.dart';

/// Streams all checklist items visible to the active user for [tripId].
final tripChecklistProvider =
    StreamProvider.family<List<ChecklistItem>, String>((ref, tripId) {
  final user = ref.watch(authStateProvider).asData?.value ??
      ref.read(authRepositoryProvider).currentUser;
  final uid = user?.uid ?? 'demo-host-an';
  return ref
      .watch(checklistRepositoryProvider)
      .watchTripChecklist(tripId, currentUserId: uid);
});

/// Loads Smart Templates (from Firestore or built-in defaults).
final checklistTemplatesProvider =
    FutureProvider<List<ChecklistTemplate>>((ref) {
  return ref.watch(checklistRepositoryProvider).getTemplates();
});

/// Handles interactive checklist mutations with AsyncValue error guarding.
final checklistControllerProvider =
    AsyncNotifierProvider<ChecklistController, void>(ChecklistController.new);

class ChecklistController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  String get _currentUid =>
      ref.read(authStateProvider).asData?.value?.uid ??
      ref.read(authRepositoryProvider).currentUser?.uid ??
      'demo-host-an';

  Future<ChecklistItem?> addItem({
    required String tripId,
    required String title,
    String? description,
    required ChecklistPhase phase,
    required ChecklistScope scope,
    String? assigneeId,
    String? assigneeName,
    DateTime? dueDate,
    int sortOrder = 0,
  }) async {
    state = const AsyncLoading();
    ChecklistItem? created;
    state = await AsyncValue.guard(() async {
      final uid = _currentUid;
      final item = ChecklistItem(
        id: '',
        tripId: tripId,
        title: title.trim(),
        description: description?.trim(),
        phase: phase,
        scope: scope,
        ownerId: scope == ChecklistScope.personal ? uid : null,
        assigneeId: assigneeId,
        assigneeName: assigneeName,
        dueDate: dueDate,
        sortOrder: sortOrder,
        createdBy: uid,
        createdAt: DateTime.now(),
      );
      created = await ref.read(checklistRepositoryProvider).addItem(item);
      if (dueDate != null) {
        final notif = ref.read(localNotificationServiceProvider);
        await notif.requestPermissionIfNeeded();
      }
    });
    return created;
  }

  Future<bool> toggleItem(ChecklistItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(checklistRepositoryProvider).toggleItemCompletion(
            item: item,
            completedBy: _currentUid,
          );
    });
    return !state.hasError;
  }

  Future<bool> assignMember({
    required ChecklistItem item,
    String? assigneeId,
    String? assigneeName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(checklistRepositoryProvider).assignMember(
            item: item,
            assigneeId: assigneeId,
            assigneeName: assigneeName,
          );
    });
    return !state.hasError;
  }

  Future<ChecklistItem?> attachProofPhoto({
    required ChecklistItem item,
    required Uint8List imageBytes,
  }) async {
    state = const AsyncLoading();
    ChecklistItem? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(checklistRepositoryProvider).attachProofPhoto(
            item: item,
            imageBytes: imageBytes,
            completedBy: _currentUid,
          );
    });
    return updated;
  }

  Future<bool> deleteItem(ChecklistItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(checklistRepositoryProvider).deleteItem(item);
    });
    return !state.hasError;
  }

  Future<int> applyTemplate({
    required TripModel trip,
    required ChecklistTemplate template,
  }) async {
    state = const AsyncLoading();
    var added = 0;
    state = await AsyncValue.guard(() async {
      added = await ref.read(checklistRepositoryProvider).applyTemplate(
            trip: trip,
            template: template,
            createdBy: _currentUid,
          );
      if (added > 0) {
        await ref.read(localNotificationServiceProvider).requestPermissionIfNeeded();
      }
    });
    return added;
  }
}
