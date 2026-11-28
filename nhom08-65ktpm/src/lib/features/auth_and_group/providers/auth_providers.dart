import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_user.dart';
import '../repository/auth_repository.dart';

/// Streams the signed-in [AppUser] (or null when signed out).
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

/// Handles interactive authentication actions (Email/Password, Google, Reset, SignOut).
final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    AppUser? signedInUser;
    state = await AsyncValue.guard(() async {
      signedInUser = await ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email: email, password: password);
    });
    return signedInUser;
  }

  Future<AppUser?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    AppUser? registeredUser;
    state = await AsyncValue.guard(() async {
      registeredUser = await ref
          .read(authRepositoryProvider)
          .registerWithEmailAndPassword(
            email: email,
            password: password,
            displayName: displayName,
          );
    });
    return registeredUser;
  }

  Future<AppUser?> signInWithGoogle() async {
    state = const AsyncLoading();
    AppUser? googleUser;
    state = await AsyncValue.guard(() async {
      googleUser = await ref.read(authRepositoryProvider).signInWithGoogle();
    });
    return googleUser;
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
    });
    return !state.hasError;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}
