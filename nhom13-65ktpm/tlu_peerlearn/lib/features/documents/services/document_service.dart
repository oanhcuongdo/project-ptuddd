import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_item.dart';
import '../utils/document_validator.dart';

final documentServiceProvider = Provider<DocumentService>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return DocumentService(client);
});

final roomDocumentsProvider =
    FutureProvider.family<List<DocumentItem>, String>((ref, roomId) async {
  final service = ref.watch(documentServiceProvider);
  return service.fetchDocuments(roomId);
});

class DocumentService {
  final SupabaseClient? _client;

  DocumentService([this._client]);

  SupabaseClient? get client => _client;

  static const String documentsTable = 'ck_documents';
  static const String storageBucket = 'room-documents';

  /// Fetches all documents uploaded for a specific room
  Future<List<DocumentItem>> fetchDocuments(String roomId) async {
    if (_client == null) return [];

    try {
      final response = await _client
          .from(documentsTable)
          .select()
          .eq('room_id', roomId)
          .order('uploaded_at', ascending: false);

      final list = (response as List<dynamic>)
          .map((row) => DocumentItem.fromJson(row as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Uploads document to Supabase Storage and records metadata into ck_documents
  Future<DocumentItem> uploadDocument({
    required String roomId,
    required String fileName,
    required Uint8List bytes,
    required String uploadedBy,
    String? topic,
  }) async {
    final validationError = DocumentValidator.validateUpload(
      fileName: fileName,
      sizeInBytes: bytes.length,
      topic: topic,
    );

    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    if (_client == null) {
      throw StateError('Supabase chưa được khởi tạo.');
    }

    final ext = fileName.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$roomId/${timestamp}_$sanitizedFileName';

    // Upload to Supabase Storage bucket
    await _client.storage.from(storageBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: ext == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            upsert: true,
          ),
        );

    final publicUrl = _client.storage.from(storageBucket).getPublicUrl(storagePath);

    // Insert metadata into database
    final record = await _client
        .from(documentsTable)
        .insert({
          'room_id': roomId,
          'file_name': fileName,
          'file_url': publicUrl,
          'file_type': ext,
          'file_size': bytes.length,
          'topic': topic?.trim().isEmpty == true ? null : topic?.trim(),
          'uploaded_by': uploadedBy,
        })
        .select()
        .single();

    return DocumentItem.fromJson(record);
  }

  /// Downloads raw file bytes from Supabase Storage using the stored file URL
  Future<Uint8List?> downloadDocumentBytes(String fileUrl) async {
    if (_client == null) return null;
    try {
      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(storageBucket);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
        return null;
      }
      final filePath = segments.sublist(bucketIndex + 1).join('/');
      return await _client.storage.from(storageBucket).download(filePath);
    } catch (_) {
      return null;
    }
  }

  /// Deletes document record and removes file from storage
  Future<void> deleteDocument({
    required String documentId,
    required String fileUrl,
  }) async {
    if (_client == null) return;

    try {
      // 1. Delete DB record
      await _client.from(documentsTable).delete().eq('id', documentId);

      // 2. Extract relative path and remove from storage
      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(storageBucket);
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        await _client.storage.from(storageBucket).remove([filePath]);
      }
    } catch (_) {
      // Ignore or log error
    }
  }
}
