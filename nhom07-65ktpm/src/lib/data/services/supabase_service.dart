import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_message_model.dart';
import '../models/nap_record_model.dart';
import '../models/sleep_goal_model.dart';
import '../models/sleep_record_model.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseService._init();

  bool _initialized = false;

  void markInitialized() {
    _initialized = true;
  }

  SupabaseClient? get _client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // --- Users ---
  Future<UserModel?> fetchUserByEmail(String email) async {
    final client = _client;
    if (client == null) return null;
    try {
      final normalized = email.trim().toLowerCase();
      final data = await client
          .from('users')
          .select()
          .eq('email', normalized)
          .maybeSingle();
      if (data == null) return null;
      return UserModel(
        name: data['name'] ?? '',
        email: data['email'] ?? normalized,
        studentId: data['student_id'] ?? '',
        className: data['class_name'] ?? '',
        createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('[SupabaseService] fetchUserByEmail error: $e');
      return null;
    }
  }

  Future<String?> fetchUserPassword(String email) async {
    final client = _client;
    if (client == null) return null;
    try {
      final data = await client
          .from('users')
          .select('password')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      return data?['password'] as String?;
    } catch (e) {
      debugPrint('[SupabaseService] fetchUserPassword error: $e');
      return null;
    }
  }

  Future<void> upsertUser(UserModel user, {String? password}) async {
    final client = _client;
    if (client == null) return;
    try {
      final payload = <String, dynamic>{
        'name': user.name,
        'email': user.email.trim().toLowerCase(),
        'student_id': user.studentId,
        'class_name': user.className,
        'created_at': user.createdAt.toIso8601String(),
      };
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }
      await client.from('users').upsert(payload, onConflict: 'email');
    } catch (e) {
      debugPrint('[SupabaseService] upsertUser error: $e');
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('users').update({
        'name': user.name,
        'student_id': user.studentId,
        'class_name': user.className,
      }).eq('email', user.email.trim().toLowerCase());
    } catch (e) {
      debugPrint('[SupabaseService] updateUserProfile error: $e');
    }
  }

  // --- Sleep Goals ---
  Future<void> syncSleepGoal(SleepGoalModel goal) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('sleep_goals').insert({
        'bedtime_hour': goal.bedtimeHour,
        'bedtime_minute': goal.bedtimeMinute,
        'wake_hour': goal.wakeHour,
        'wake_minute': goal.wakeMinute,
        'target_duration_hours': goal.targetDurationHours,
        'active_days': goal.activeDays,
        'is_reminder_enabled': goal.isReminderEnabled,
      });
    } catch (e) {
      debugPrint('[SupabaseService] syncSleepGoal error: $e');
    }
  }

  // --- Sleep Records ---
  Future<void> syncSleepRecord(SleepRecordModel record) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('sleep_records').insert({
        'sleep_time': record.sleepTime.toIso8601String(),
        'wake_time': record.wakeTime.toIso8601String(),
        'duration_hours': record.durationHours,
        'wake_up_count': record.wakeUpCount,
        'feeling_rating': record.feelingRating,
        'note': record.note,
        'is_goal_met': record.isGoalMet,
        'created_at': record.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] syncSleepRecord error: $e');
    }
  }

  // --- Nap Records ---
  Future<void> syncNapRecord(NapRecordModel nap) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('nap_records').insert({
        'start_time': nap.startTime.toIso8601String(),
        'duration_minutes': nap.durationMinutes,
        'note': nap.note,
        'created_at': nap.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] syncNapRecord error: $e');
    }
  }

  // --- AI Messages ---
  Future<void> syncAIMessage(AIMessageModel message) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('ai_messages').insert({
        'text': message.text,
        'is_user': message.isUser,
        'is_offline': message.isOffline,
        'timestamp': message.timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] syncAIMessage error: $e');
    }
  }

  Future<void> clearAIMessages() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('ai_messages').delete().gte('id', 0);
    } catch (e) {
      debugPrint('[SupabaseService] clearAIMessages error: $e');
    }
  }
}
