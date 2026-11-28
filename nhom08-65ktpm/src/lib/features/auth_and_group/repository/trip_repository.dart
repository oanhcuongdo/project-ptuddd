import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_storage_service.dart';
import '../../../models/app_user.dart';
import '../../../models/invite_code.dart';
import '../../../models/trip_member.dart';
import '../../../models/trip_model.dart';

class TripFailure implements Exception {
  final String message;
  const TripFailure(this.message);

  @override
  String toString() => message;
}

abstract class TripRepository {
  Stream<List<TripModel>> watchUserTrips(String userId);
  Stream<TripModel?> watchTrip(String tripId);
  Stream<List<TripMember>> watchTripMembers(String tripId);

  Future<TripModel> createTrip({
    required AppUser host,
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int targetBudget,
    TripType tripType = TripType.other,
    String savingFrequency = 'weekly',
    Uint8List? coverImageBytes,
    String? customInviteCode,
  });

  Future<InviteCode?> lookupInviteCode(String rawCode);

  Future<TripModel> joinTripByCode({
    required String rawCode,
    required AppUser user,
  });

  /// Normalizes raw QR string or direct invite code into uppercase code.
  static String normalizeInviteCode(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final queryCode = uri.queryParameters['code'];
      if (queryCode != null && queryCode.trim().isNotEmpty) {
        return queryCode.trim().toUpperCase();
      }
      if (uri.pathSegments.isNotEmpty && uri.scheme.isNotEmpty) {
        return uri.pathSegments.last.trim().toUpperCase();
      }
    }
    return trimmed.toUpperCase();
  }

  /// Generates a 6-character unambiguous uppercase invite code.
  static String generateInviteCode([Random? random]) {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rng = random ?? Random.secure();
    final buffer = StringBuffer('TB');
    for (var i = 0; i < 4; i++) {
      buffer.write(chars[rng.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return InMemoryTripRepository();
  }
  return FirestoreTripRepository(
    firestore: FirebaseFirestore.instance,
    storageService: ref.watch(supabaseStorageServiceProvider),
  );
});

class FirestoreTripRepository implements TripRepository {
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storageService;

  FirestoreTripRepository({
    FirebaseFirestore? firestore,
    SupabaseStorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? SupabaseStorageService();

  CollectionReference<Map<String, dynamic>> get _tripsColl =>
      _firestore.collection('trips');

  CollectionReference<Map<String, dynamic>> get _inviteCodesColl =>
      _firestore.collection('invite_codes');

  CollectionReference<Map<String, dynamic>> get _usersColl =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _membersColl(String tripId) =>
      _tripsColl.doc(tripId).collection('members');

  @override
  Stream<List<TripModel>> watchUserTrips(String userId) {
    return _tripsColl
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => TripModel.fromJson({...d.data(), 'id': d.id}))
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate)),
        );
  }

  @override
  Stream<TripModel?> watchTrip(String tripId) {
    return _tripsColl.doc(tripId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return TripModel.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  @override
  Stream<List<TripMember>> watchTripMembers(String tripId) {
    return _membersColl(tripId).orderBy('joinedAt').snapshots().map(
          (snapshot) => snapshot.docs
              .map((d) => TripMember.fromJson({...d.data(), 'userId': d.id}))
              .toList(),
        );
  }

  @override
  Future<TripModel> createTrip({
    required AppUser host,
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
    final tripRef = _tripsColl.doc();
    final now = DateTime.now();
    final inviteCode = await _allocateInviteCode(customInviteCode);

    String? coverUrl;
    String? coverPath;
    if (coverImageBytes != null) {
      final path = 'trips/${tripRef.id}/cover/cover_${now.millisecondsSinceEpoch}.jpg';
      coverUrl = await _storageService.uploadBytes(
        path: path,
        bytes: coverImageBytes,
      );
      coverPath = path;
    }

    final trip = TripModel(
      id: tripRef.id,
      title: title.trim(),
      destination: destination.trim(),
      tripType: tripType,
      coverImageUrl: coverUrl,
      coverStoragePath: coverPath,
      startDate: startDate,
      endDate: endDate,
      hostId: host.uid,
      memberIds: [host.uid],
      inviteCode: inviteCode,
      status: TripStatus.planning,
      targetBudget: targetBudget,
      perMemberTarget: targetBudget,
      savingFrequency: savingFrequency,
      createdAt: now,
      updatedAt: now,
    );

    final hostMember = TripMember(
      userId: host.uid,
      displayName: host.displayName,
      avatarUrl: host.avatarUrl,
      role: TripRole.host,
      targetContribution: targetBudget,
      joinedAt: now,
    );

    final inviteDoc = InviteCode(
      code: inviteCode,
      tripId: tripRef.id,
      tripTitle: trip.title,
      createdBy: host.uid,
      isActive: true,
      createdAt: now,
    );

    final batch = _firestore.batch();
    batch.set(tripRef, trip.toJson());
    batch.set(_membersColl(tripRef.id).doc(host.uid), hostMember.toJson());
    batch.set(_inviteCodesColl.doc(inviteCode), inviteDoc.toJson());
    batch.set(
      _usersColl.doc(host.uid),
      {
        'uid': host.uid,
        'email': host.email,
        'displayName': host.displayName,
        'tripIds': FieldValue.arrayUnion([tripRef.id]),
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    return trip;
  }

  @override
  Future<InviteCode?> lookupInviteCode(String rawCode) async {
    final code = TripRepository.normalizeInviteCode(rawCode);
    if (code.isEmpty) return null;
    final snap = await _inviteCodesColl.doc(code).get();
    if (!snap.exists || snap.data() == null) return null;
    return InviteCode.fromJson({...snap.data()!, 'code': snap.id});
  }

  @override
  Future<TripModel> joinTripByCode({
    required String rawCode,
    required AppUser user,
  }) async {
    final invite = await lookupInviteCode(rawCode);
    if (invite == null || !invite.isActive) {
      throw const TripFailure('Mã mời không tồn tại hoặc đã bị vô hiệu hóa.');
    }
    if (invite.expiresAt != null && invite.expiresAt!.isBefore(DateTime.now())) {
      throw const TripFailure('Mã mời này đã hết hạn.');
    }

    final tripRef = _tripsColl.doc(invite.tripId);
    final memberRef = _membersColl(invite.tripId).doc(user.uid);
    final userRef = _usersColl.doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final tripSnap = await transaction.get(tripRef);
      if (!tripSnap.exists || tripSnap.data() == null) {
        throw const TripFailure('Chuyến đi này không còn tồn tại.');
      }

      final trip = TripModel.fromJson({...tripSnap.data()!, 'id': tripSnap.id});
      if (trip.memberIds.contains(user.uid)) {
        return trip;
      }

      final now = DateTime.now();
      final updatedMemberIds = [...trip.memberIds, user.uid];
      final perMemberTarget = updatedMemberIds.isEmpty
          ? trip.targetBudget
          : (trip.targetBudget / updatedMemberIds.length).round();

      final newMember = TripMember(
        userId: user.uid,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        role: TripRole.member,
        targetContribution: perMemberTarget,
        joinedAt: now,
      );

      transaction.update(tripRef, {
        'memberIds': FieldValue.arrayUnion([user.uid]),
        'perMemberTarget': perMemberTarget,
        'updatedAt': Timestamp.fromDate(now),
      });
      transaction.set(memberRef, newMember.toJson());
      transaction.set(
        userRef,
        {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'tripIds': FieldValue.arrayUnion([trip.id]),
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      return trip.copyWith(
        memberIds: updatedMemberIds,
        perMemberTarget: perMemberTarget,
        updatedAt: now,
      );
    });
  }

  Future<String> _allocateInviteCode(String? preferredCode) async {
    final normalized = preferredCode == null
        ? ''
        : TripRepository.normalizeInviteCode(preferredCode);
    if (normalized.isNotEmpty) {
      final existing = await _inviteCodesColl.doc(normalized).get();
      if (!existing.exists) return normalized;
    }

    for (var attempt = 0; attempt < 5; attempt++) {
      final candidate = TripRepository.generateInviteCode();
      final existing = await _inviteCodesColl.doc(candidate).get();
      if (!existing.exists) return candidate;
    }
    return 'TB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }
}

/// Offline/preview fallback repository used when Firebase is not initialized.
class InMemoryTripRepository implements TripRepository {
  final _tripsController = StreamController<List<TripModel>>.broadcast();
  final Map<String, TripModel> _trips = {};
  final Map<String, List<TripMember>> _members = {};
  final Map<String, InviteCode> _invites = {};

  InMemoryTripRepository() {
    final now = DateTime.now();
    final start = now.add(const Duration(days: 14));
    final end = start.add(const Duration(days: 3));

    const tripId = 'demo-trip';
    const inviteCode = 'TB8K4M';
    final demoTrip = TripModel(
      id: tripId,
      title: 'Đà Lạt 4N3Đ',
      destination: 'Đà Lạt, Lâm Đồng',
      startDate: start,
      endDate: end,
      hostId: 'demo-host-an',
      memberIds: const [
        'demo-host-an',
        'demo-member-binh',
        'demo-member-dung',
        'demo-member-khanh',
      ],
      inviteCode: inviteCode,
      status: TripStatus.planning,
      targetBudget: 8450000,
      perMemberTarget: 2112500,
      checklistTotal: 12,
      checklistCompleted: 8,
      totalSavedAmount: 5500000,
      createdAt: now,
      updatedAt: now,
    );
    _trips[tripId] = demoTrip;
    _invites[inviteCode] = InviteCode(
      code: inviteCode,
      tripId: tripId,
      tripTitle: demoTrip.title,
      createdBy: 'demo-host-an',
      createdAt: now,
    );
    _members[tripId] = [
      TripMember(
        userId: 'demo-host-an',
        displayName: 'Đỗ Đình An',
        role: TripRole.host,
        targetContribution: 2112500,
        contributedAmount: 1500000,
        currentStreak: 4,
        joinedAt: now,
      ),
      TripMember(
        userId: 'demo-member-binh',
        displayName: 'Nguyễn Xuân Bình',
        role: TripRole.member,
        targetContribution: 2112500,
        contributedAmount: 1500000,
        currentStreak: 3,
        joinedAt: now,
      ),
      TripMember(
        userId: 'demo-member-dung',
        displayName: 'Hồ Thế Dũng',
        role: TripRole.member,
        targetContribution: 2112500,
        contributedAmount: 1250000,
        currentStreak: 2,
        joinedAt: now,
      ),
      TripMember(
        userId: 'demo-member-khanh',
        displayName: 'Đỗ Tùng Khánh',
        role: TripRole.member,
        targetContribution: 2112500,
        contributedAmount: 1250000,
        currentStreak: 2,
        joinedAt: now,
      ),
    ];
  }

  @override
  Stream<List<TripModel>> watchUserTrips(String userId) async* {
    List<TripModel> filter() => _trips.values
        .where((t) => t.memberIds.contains(userId))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    yield filter();
    await for (final _ in _tripsController.stream) {
      yield filter();
    }
  }

  @override
  Stream<TripModel?> watchTrip(String tripId) async* {
    yield _trips[tripId];
    await for (final _ in _tripsController.stream) {
      yield _trips[tripId];
    }
  }

  @override
  Stream<List<TripMember>> watchTripMembers(String tripId) async* {
    yield List.unmodifiable(_members[tripId] ?? const []);
    await for (final _ in _tripsController.stream) {
      yield List.unmodifiable(_members[tripId] ?? const []);
    }
  }

  @override
  Future<TripModel> createTrip({
    required AppUser host,
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
    final now = DateTime.now();
    final tripId = 'trip-${now.millisecondsSinceEpoch}';
    final code = (customInviteCode != null && customInviteCode.trim().isNotEmpty)
        ? TripRepository.normalizeInviteCode(customInviteCode)
        : TripRepository.generateInviteCode();

    final trip = TripModel(
      id: tripId,
      title: title.trim(),
      destination: destination.trim(),
      tripType: tripType,
      startDate: startDate,
      endDate: endDate,
      hostId: host.uid,
      memberIds: [host.uid],
      inviteCode: code,
      status: TripStatus.planning,
      targetBudget: targetBudget,
      perMemberTarget: targetBudget,
      savingFrequency: savingFrequency,
      createdAt: now,
      updatedAt: now,
    );
    _trips[tripId] = trip;
    _invites[code] = InviteCode(
      code: code,
      tripId: tripId,
      tripTitle: trip.title,
      createdBy: host.uid,
      createdAt: now,
    );
    _members[tripId] = [
      TripMember(
        userId: host.uid,
        displayName: host.displayName,
        avatarUrl: host.avatarUrl,
        role: TripRole.host,
        targetContribution: targetBudget,
        joinedAt: now,
      ),
    ];
    _tripsController.add(_trips.values.toList());
    return trip;
  }

  @override
  Future<InviteCode?> lookupInviteCode(String rawCode) async {
    final code = TripRepository.normalizeInviteCode(rawCode);
    return _invites[code];
  }

  @override
  Future<TripModel> joinTripByCode({
    required String rawCode,
    required AppUser user,
  }) async {
    final invite = await lookupInviteCode(rawCode);
    if (invite == null || !invite.isActive) {
      throw const TripFailure('Mã mời không tồn tại hoặc đã bị vô hiệu hóa.');
    }
    final trip = _trips[invite.tripId];
    if (trip == null) {
      throw const TripFailure('Chuyến đi này không còn tồn tại.');
    }
    if (trip.memberIds.contains(user.uid)) return trip;

    final now = DateTime.now();
    final updatedIds = [...trip.memberIds, user.uid];
    final perMember = updatedIds.isEmpty
        ? trip.targetBudget
        : (trip.targetBudget / updatedIds.length).round();
    final updated = trip.copyWith(
      memberIds: updatedIds,
      perMemberTarget: perMember,
      updatedAt: now,
    );
    _trips[trip.id] = updated;
    _members.putIfAbsent(trip.id, () => []).add(
          TripMember(
            userId: user.uid,
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
            role: TripRole.member,
            targetContribution: perMember,
            joinedAt: now,
          ),
        );
    _tripsController.add(_trips.values.toList());
    return updated;
  }
}
