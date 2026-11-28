import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/entities/attempt_log.dart';
import '../../shared/entities/child_profile.dart';

class StorageService {
  static const String _keyProfile = 'soroban_child_profile';
  static const String _keyLogs = 'soroban_attempt_logs';
  static const String _legacyOwnerKey = 'soroban_legacy_data_owner_uid';

  String? _lastCloudSyncError;

  String? get lastCloudSyncError => _lastCloudSyncError;

  String? get _currentUid {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  DocumentReference<Map<String, dynamic>> _profileDocument(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('data')
          .doc('childProfile');

  CollectionReference<Map<String, dynamic>> _attemptCollection(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('attempts');

  String _scopedKey(String key, String uid) => '${key}_$uid';

  Future<String> _resolveLocalKey(
    SharedPreferences prefs,
    String key,
    String? uid,
  ) async {
    if (uid == null) return key;

    final scopedKey = _scopedKey(key, uid);
    if (prefs.containsKey(scopedKey)) return scopedKey;

    final legacyOwner = prefs.getString(_legacyOwnerKey);
    final hasLegacyData =
        prefs.containsKey(_keyProfile) || prefs.containsKey(_keyLogs);
    if (legacyOwner == uid || (legacyOwner == null && hasLegacyData)) {
      if (legacyOwner == null) {
        await prefs.setString(_legacyOwnerKey, uid);
      }
      return key;
    }

    return scopedKey;
  }

  Future<ChildProfile> getChildProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUid;
    final localKey = await _resolveLocalKey(prefs, _keyProfile, uid);

    if (uid != null) {
      try {
        final document = await _profileDocument(uid).get();
        if (document.exists && document.data() != null) {
          final profile =
              ChildProfile.fromMap(document.data()!).copyWith(id: uid);
          await prefs.setString(
            _scopedKey(_keyProfile, uid),
            jsonEncode(profile.toMap()),
          );
          _lastCloudSyncError = null;
          return profile;
        }
      } on FirebaseException catch (error) {
        _recordCloudError(error);
        return _readLocalProfile(prefs, localKey, uid);
      } catch (error) {
        _recordCloudError(error);
        return _readLocalProfile(prefs, localKey, uid);
      }
    }

    final profile = _readLocalProfile(prefs, localKey, uid);
    if (uid != null) {
      final scopedProfile = profile.copyWith(id: uid);
      await prefs.setString(
        _scopedKey(_keyProfile, uid),
        jsonEncode(scopedProfile.toMap()),
      );
      try {
        await _profileDocument(uid).set(scopedProfile.toMap());
        _lastCloudSyncError = null;
      } catch (error) {
        _recordCloudError(error);
      }
      return scopedProfile;
    }
    return profile;
  }

  ChildProfile _readLocalProfile(
    SharedPreferences prefs,
    String key,
    String? uid,
  ) {
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          final profile = ChildProfile.fromMap(decoded);
          return uid == null ? profile : profile.copyWith(id: uid);
        }
      } on FormatException {
        // Treat malformed persisted JSON as a profile without progress.
      }
    }

    return ChildProfile(
      id: uid ?? 'child_default',
      name: 'Bé Yêu',
      age: 5,
      streakCount: 0,
      longestStreak: 0,
      lastActiveDate: '',
      unlockedBadgeIds: const [],
      currentLevel: 1,
    );
  }

  Future<void> saveChildProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUid;
    final localKey = await _resolveLocalKey(prefs, _keyProfile, uid);
    final scopedProfile = uid == null ? profile : profile.copyWith(id: uid);

    await prefs.setString(localKey, jsonEncode(scopedProfile.toMap()));
    if (uid == null) return;

    await prefs.setString(
      _scopedKey(_keyProfile, uid),
      jsonEncode(scopedProfile.toMap()),
    );
    try {
      await _profileDocument(uid).set(scopedProfile.toMap());
      _lastCloudSyncError = null;
    } catch (error) {
      _recordCloudError(error);
    }
  }

  Future<void> saveAttemptLog(AttemptLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUid;
    final localKey = await _resolveLocalKey(prefs, _keyLogs, uid);
    final logs = await getRecentLogs();
    logs.removeWhere((existing) => _attemptKey(existing) == _attemptKey(log));
    logs.insert(0, log);
    if (logs.length > 50) logs.removeRange(50, logs.length);
    await prefs.setString(
      localKey,
      jsonEncode(logs.map((entry) => entry.toMap()).toList()),
    );

    if (uid == null) return;

    await prefs.setString(
      _scopedKey(_keyLogs, uid),
      jsonEncode(logs.map((entry) => entry.toMap()).toList()),
    );
    try {
      await _writeAttemptLog(uid, log);
      _lastCloudSyncError = null;
    } catch (error) {
      _recordCloudError(error);
    }
  }

  Future<List<AttemptLog>> getRecentLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUid;
    final localKey = await _resolveLocalKey(prefs, _keyLogs, uid);
    final localLogs = _readLocalLogs(prefs, localKey);
    if (uid == null) return localLogs;

    try {
      final snapshot = await _attemptCollection(uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      final remoteLogs = snapshot.docs
          .map((document) => AttemptLog.fromMap(document.data()))
          .toList();
      final remoteKeys = remoteLogs.map(_attemptKey).toSet();
      final pendingLogs =
          localLogs.where((log) => !remoteKeys.contains(_attemptKey(log)));
      if (pendingLogs.isNotEmpty) {
        await _writeAttemptLogs(uid, pendingLogs);
      }

      final logs = _mergeLogs(remoteLogs, localLogs);
      await prefs.setString(
        _scopedKey(_keyLogs, uid),
        jsonEncode(logs.map((entry) => entry.toMap()).toList()),
      );
      _lastCloudSyncError = null;
      return logs;
    } catch (error) {
      _recordCloudError(error);
      return localLogs;
    }
  }

  List<AttemptLog> _readLocalLogs(SharedPreferences prefs, String key) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((entry) => AttemptLog.fromMap(
                  Map<String, dynamic>.from(entry),
                ))
            .toList();
      }
    } catch (_) {
      // Ignore a damaged local cache and continue with an empty history.
    }
    return [];
  }

  List<AttemptLog> _mergeLogs(
    List<AttemptLog> remoteLogs,
    List<AttemptLog> localLogs,
  ) {
    final byKey = <String, AttemptLog>{};
    for (final log in [...remoteLogs, ...localLogs]) {
      byKey.putIfAbsent(_attemptKey(log), () => log);
    }
    final merged = byKey.values.toList()
      ..sort((first, second) {
        final firstDate = DateTime.tryParse(first.timestamp);
        final secondDate = DateTime.tryParse(second.timestamp);
        if (firstDate == null || secondDate == null) return 0;
        return secondDate.compareTo(firstDate);
      });
    if (merged.length > 50) merged.removeRange(50, merged.length);
    return merged;
  }

  String _attemptKey(AttemptLog log) =>
      '${log.questionId}|${log.timestamp}|${log.userAnswer}|${log.answeredVia}';

  String _attemptDocumentId(AttemptLog log) =>
      base64Url.encode(utf8.encode(_attemptKey(log))).replaceAll('=', '');

  Timestamp _createdAt(AttemptLog log) {
    final parsed = DateTime.tryParse(log.timestamp);
    return Timestamp.fromDate((parsed ?? DateTime.now()).toUtc());
  }

  Future<void> _writeAttemptLog(String uid, AttemptLog log) async {
    await _attemptCollection(uid)
        .doc(_attemptDocumentId(log))
        .set({...log.toMap(), 'createdAt': _createdAt(log)});
  }

  Future<void> _writeAttemptLogs(String uid, Iterable<AttemptLog> logs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final log in logs) {
      batch.set(
        _attemptCollection(uid).doc(_attemptDocumentId(log)),
        {...log.toMap(), 'createdAt': _createdAt(log)},
      );
    }
    await batch.commit();
  }

  void _recordCloudError(Object error) {
    _lastCloudSyncError = error is FirebaseException
        ? '${error.code}: ${error.message ?? 'Firebase error'}'
        : error.toString();
  }
}
