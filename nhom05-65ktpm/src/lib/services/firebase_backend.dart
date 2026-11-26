import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseRuntime {
  static const enabled = bool.fromEnvironment('FIREBASE_ENABLED');
  static Object? initializationError;

  static Future<void> initialize() async {
    if (!enabled) return;
    try {
      await Firebase.initializeApp();
    } catch (error) {
      initializationError = error;
      rethrow;
    }
  }
}

enum AccountRole { learner, mentor }

class AccountProfile {
  final String uid;
  final String displayName;
  final String email;
  final AccountRole role;
  final String? groupId;

  const AccountProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.groupId,
  });

  factory AccountProfile.fromDocument(String uid, Map<String, dynamic> data) =>
      AccountProfile(
        uid: uid,
        displayName: data['displayName'] as String? ?? 'Learner',
        email: data['email'] as String? ?? '',
        role: data['role'] == 'mentor'
            ? AccountRole.mentor
            : AccountRole.learner,
        groupId: data['groupId'] as String?,
      );
}

class FirebaseAccountRepository {
  final auth.FirebaseAuth _auth;
  final FirebaseFirestore _store;
  StreamSubscription<String>? _tokenRefreshSubscription;

  FirebaseAccountRepository({
    auth.FirebaseAuth? authClient,
    FirebaseFirestore? store,
  }) : _auth = authClient ?? auth.FirebaseAuth.instance,
       _store = store ?? FirebaseFirestore.instance;

  Stream<auth.User?> authChanges() => _auth.authStateChanges();

  Future<String?> _currentMessagingToken() async {
    // Admin SDK multicast delivery targets FCM tokens, not installation IDs.
    // ignore: deprecated_member_use
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> registerLearner({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Firebase Auth returned no user.');
    await user.updateDisplayName(name.trim());
    try {
      await _store.collection('users').doc(user.uid).set({
        'displayName': name.trim(),
        'email': email.trim(),
        // Public registration can never grant mentor privileges.
        'role': 'learner',
        'rate': null,
        'rateLevel': null,
        'attemptCount': 0,
        'groupId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await user.delete();
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signOut() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    final user = _auth.currentUser;
    if (user != null) {
      final token = await _currentMessagingToken();
      if (token != null) {
        await _store
            .collection('users')
            .doc(user.uid)
            .collection('private')
            .doc('device')
            .set({
              'tokens': FieldValue.arrayRemove([token]),
            }, SetOptions(merge: true));
      }
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Stream<AccountProfile?> watchProfile(String uid) => _store
      .collection('users')
      .doc(uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? AccountProfile.fromDocument(uid, snapshot.data()!)
            : null,
      );

  Future<void> registerPushToken(String uid) async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    final token = await _currentMessagingToken();
    if (token == null) return;
    await _store
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('device')
        .set({
          'tokens': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
    await _tokenRefreshSubscription?.cancel();
    // ignore: deprecated_member_use
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((freshToken) {
      _store
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('device')
          .set({
            'tokens': FieldValue.arrayUnion([freshToken]),
          }, SetOptions(merge: true));
    });
  }
}
