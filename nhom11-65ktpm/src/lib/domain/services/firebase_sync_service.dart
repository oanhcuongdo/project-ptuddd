import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../database/app_database.dart';

class FirebaseSyncService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;

  FirebaseSyncService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _customFirestore = firestore,
        _customStorage = storage;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get _storage {
    if (_customStorage != null) return _customStorage;
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Đồng bộ danh sách tài liệu học tập lên Cloud Firestore
  Future<void> syncDocumentsToFirestore({
    required String userId,
    required List<Document> documents,
    required List<Subject> subjects,
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      throw Exception('Cloud Firestore chưa được khởi tạo.');
    }
    try {
      final batch = firestore.batch();
      final userDocRef = firestore.collection('users').doc(userId);

      // 1. Lưu danh mục môn học
      for (final subject in subjects) {
        final subjectRef = userDocRef.collection('subjects').doc(subject.subjectPk);
        batch.set(subjectRef, {
          'subjectPk': subject.subjectPk,
          'code': subject.code,
          'name': subject.name,
          'lecturer': subject.lecturer,
          'semester': subject.semester,
          'colorHex': subject.colorHex,
          'dateTimeModified': subject.dateTimeModified.toIso8601String(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Lưu tài liệu học tập
      for (final doc in documents) {
        final docRef = userDocRef.collection('documents').doc(doc.documentPk);
        batch.set(docRef, {
          'documentPk': doc.documentPk,
          'title': doc.title,
          'subjectFk': doc.subjectFk,
          'docType': doc.docType,
          'content': doc.content,
          'fileUrl': doc.fileUrl,
          'priority': doc.priority,
          'status': doc.status,
          'dateTimeCreated': doc.dateTimeCreated.toIso8601String(),
          'dateTimeModified': doc.dateTimeModified.toIso8601String(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('Đã đồng bộ thành công ${documents.length} tài liệu lên Firestore!');
    } catch (e) {
      debugPrint('Lỗi đồng bộ Firestore: $e');
      rethrow;
    }
  }

  /// Tải tệp nhị phân (PDF, Slide, Ảnh bài giảng) lên Firebase Cloud Storage
  Future<String> uploadFileToStorage({
    required String userId,
    required String fileName,
    required Uint8List fileBytes,
    String contentType = 'application/pdf',
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage chưa được khởi tạo.');
    }
    try {
      final storageRef = storage
          .ref()
          .child('users/$userId/documents/$fileName');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = await storageRef.putData(fileBytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('Tải tệp lên Firebase Storage thành công: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Lỗi tải tệp lên Firebase Storage: $e');
      rethrow;
    }
  }

  /// Tải danh sách tài liệu đã lưu trên Firestore về máy
  Future<Map<String, dynamic>> fetchUserDataFromFirestore(String userId) async {
    final firestore = _firestore;
    if (firestore == null) {
      throw Exception('Cloud Firestore chưa được khởi tạo.');
    }
    try {
      final userDocRef = firestore.collection('users').doc(userId);

      final subjectsSnapshot = await userDocRef.collection('subjects').get();
      final docsSnapshot = await userDocRef.collection('documents').get();

      final subjects = subjectsSnapshot.docs.map((d) => d.data()).toList();
      final documents = docsSnapshot.docs.map((d) => d.data()).toList();

      return {
        'subjects': subjects,
        'documents': documents,
      };
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu từ Firestore: $e');
      rethrow;
    }
  }
}
