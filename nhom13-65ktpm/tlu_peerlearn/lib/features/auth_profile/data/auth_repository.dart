import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Re-evaluate whenever auth state changes
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).getCurrentProfile();
});

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? studentId,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );

    final user = response.user;
    if (user != null) {
      await _client.from('ck_profiles').upsert({
        'id': user.id,
        'email': email.trim(),
        'full_name': fullName.trim(),
        'student_id': studentId?.trim().isEmpty == true ? null : studentId?.trim(),
        'role': 'student',
      });
    }
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('ck_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      final fallbackProfile = {
        'id': user.id,
        'email': user.email ?? '',
        'full_name': (user.userMetadata?['full_name'] as String?) ??
            (user.email?.split('@').first ?? 'Sinh viên'),
        'role': 'student',
      };
      await _client.from('ck_profiles').upsert(fallbackProfile);
      return UserProfile.fromJson(fallbackProfile);
    }
    return UserProfile.fromJson(data);
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? studentId,
    String? faculty,
    String? className,
    String? phone,
    String? avatarUrl,
  }) async {
    await _client.from('ck_profiles').update({
      'full_name': fullName.trim(),
      'student_id': studentId?.trim().isEmpty == true ? null : studentId?.trim(),
      'faculty': faculty?.trim().isEmpty == true ? null : faculty?.trim(),
      'class_name': className?.trim().isEmpty == true ? null : className?.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'avatar_url': avatarUrl?.trim().isEmpty == true ? null : avatarUrl?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}

