import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration for Supabase Storage (used instead of Firebase Cloud Storage).
///
/// Provide values via `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// or update the default constants below before building.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rktaijorhwlnqemznbev.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_iuc7agPyVIFUCHaYZoAc1w_nN9mbkg1',
  );
  static const String bucket = String.fromEnvironment(
    'SUPABASE_BUCKET',
    defaultValue: 'travel-buddy',
  );

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>(
  (ref) => SupabaseStorageService(),
);

/// Shared wrapper around Supabase Storage for uploading trip receipts,
/// check-in photos, checklist proofs, and expense receipts.
class SupabaseStorageService {
  final SupabaseClient? _clientOverride;
  final String bucket;

  SupabaseStorageService({
    SupabaseClient? client,
    this.bucket = SupabaseConfig.bucket,
  }) : _clientOverride = client;

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// Initializes Supabase if [SupabaseConfig.isConfigured] is true.
  /// Never throws if unconfigured so offline previews and widget tests keep booting.
  static Future<void> initializeSafely() async {
    if (_initialized || !SupabaseConfig.isConfigured) {
      if (!SupabaseConfig.isConfigured) {
        debugPrint(
          'Supabase Storage skipped: set SUPABASE_URL and SUPABASE_ANON_KEY.',
        );
      }
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url.trim(),
        publishableKey: SupabaseConfig.anonKey.trim(),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Supabase initialization skipped: $e');
    }
  }

  SupabaseClient _resolveClient() {
    if (_clientOverride != null) return _clientOverride;
    if (!_initialized) {
      throw StateError(
        'Supabase Storage chưa được cấu hình. '
        'Hãy điền SUPABASE_URL và SUPABASE_ANON_KEY trong lib/core/services/supabase_storage_service.dart '
        'hoặc truyền qua --dart-define.',
      );
    }
    return Supabase.instance.client;
  }

  /// Uploads raw image bytes to [path] in Supabase Storage and returns its public URL.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? bucket,
  }) async {
    final targetBucket = bucket ?? this.bucket;
    final storage = _resolveClient().storage.from(targetBucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return storage.getPublicUrl(path);
  }

  /// Uploads a local [file] to [path] in Supabase Storage and returns its public URL.
  Future<String> uploadFile({
    required String path,
    required File file,
    String contentType = 'image/jpeg',
    String? bucket,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadBytes(
      path: path,
      bytes: bytes,
      contentType: contentType,
      bucket: bucket,
    );
  }

  /// Deletes a single object at [path] from Supabase Storage.
  Future<void> deleteFile(String path, {String? bucket}) async {
    if (path.trim().isEmpty) return;
    await deleteFiles([path], bucket: bucket);
  }

  /// Deletes multiple objects at [paths] from Supabase Storage.
  Future<void> deleteFiles(List<String> paths, {String? bucket}) async {
    final cleanPaths = paths.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (cleanPaths.isEmpty) return;
    final targetBucket = bucket ?? this.bucket;
    await _resolveClient().storage.from(targetBucket).remove(cleanPaths);
  }
}
