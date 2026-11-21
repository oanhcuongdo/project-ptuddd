import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../domain/program_registration.dart';
import 'auth_repository.dart';

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(ref.watch(supabaseClientProvider));
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  return ref.watch(registrationRepositoryProvider).getCourses();
});

final myRegistrationsProvider =
    FutureProvider<List<ProgramRegistration>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(registrationRepositoryProvider).getMyRegistrations(profile.id);
});

class RegistrationRepository {
  final SupabaseClient _client;

  RegistrationRepository(this._client);

  Future<List<Course>> getCourses() async {
    final data = await _client.from('ck_courses').select().order('code');
    return (data as List<dynamic>)
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProgramRegistration>> getMyRegistrations(String userId) async {
    final data = await _client
        .from('ck_program_registrations')
        .select('*, ck_courses(code, name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => ProgramRegistration.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertRegistration({
    required String userId,
    required String courseId,
    required String role,
    double? courseGrade,
    String? strengthsOrNeeds,
    int maxMentees = 5,
    required List<int> availableSlots,
  }) async {
    await _client.from('ck_program_registrations').upsert(
      {
        'user_id': userId,
        'course_id': courseId,
        'role': role,
        'course_grade': role == 'mentor' ? courseGrade : null,
        'strengths_or_needs': strengthsOrNeeds?.trim(),
        'max_mentees': role == 'mentor' ? maxMentees : 5,
        'available_slots': availableSlots..sort(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,course_id',
    );
  }

  Future<void> deleteRegistration(String registrationId) async {
    await _client
        .from('ck_program_registrations')
        .delete()
        .eq('id', registrationId);
  }
}

