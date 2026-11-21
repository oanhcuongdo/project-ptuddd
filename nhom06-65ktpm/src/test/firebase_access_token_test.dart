import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthylife/features/auth/data/firebase_auth_repository.dart';
import 'package:healthylife/features/auth/domain/auth_repository.dart';

void main() {
  test(
    'Supabase gets the current Firebase token only after the claim is set',
    () async {
      final firebase = _Firebase();
      final auth = FirebaseAuthRepository(firebase);
      expect(await auth.accessToken(), isNull);

      final user = _User('user-a', Future.value(_Token('user-a')));
      firebase.user = user;
      expect(await auth.hasDataAccess(), isFalse);
      await expectLater(
        auth.accessToken(),
        throwsA(AuthFailure.awaitingDataAccess),
      );

      user.result = Future.value(_Token('user-a', role: 'authenticated'));
      expect(await auth.hasDataAccess(refresh: true), isTrue);
      expect(user.refreshed, isTrue);
      expect(await auth.accessToken(), 'test-token-for-user-a');

      await auth.signOut();
      expect(await auth.accessToken(), isNull);
    },
  );

  test('a token fetched before an account switch is discarded', () async {
    final pending = Completer<IdTokenResult>();
    final firebase = _Firebase()..user = _User('user-a', pending.future);
    final auth = FirebaseAuthRepository(firebase);
    final access = auth.accessToken();
    firebase.user = _User(
      'user-b',
      Future.value(_Token('user-b', role: 'authenticated')),
    );
    pending.complete(_Token('user-a', role: 'authenticated'));

    await expectLater(access, throwsA(AuthFailure.sessionExpired));
    expect(await auth.accessToken(), 'test-token-for-user-b');
  });

  test(
    'a token with a different subject cannot be attached to a request',
    () async {
      final firebase = _Firebase()
        ..user = _User(
          'user-a',
          Future.value(_Token('user-b', role: 'authenticated')),
        );
      final auth = FirebaseAuthRepository(firebase);
      await expectLater(
        auth.accessToken(),
        throwsA(AuthFailure.sessionExpired),
      );
    },
  );
}

class _Firebase extends Fake implements FirebaseAuth {
  User? user;

  @override
  User? get currentUser => user;

  @override
  Future<void> signOut() async => user = null;
}

class _User extends Fake implements User {
  _User(this.uid, this.result);

  @override
  final String uid;
  Future<IdTokenResult> result;
  bool refreshed = false;

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) {
    refreshed = forceRefresh;
    return result;
  }
}

class _Token extends Fake implements IdTokenResult {
  _Token(String uid, {String? role})
    : token = 'test-token-for-$uid',
      claims = {'sub': uid, 'role': ?role};

  @override
  final String token;
  @override
  final Map<String, dynamic> claims;
}
