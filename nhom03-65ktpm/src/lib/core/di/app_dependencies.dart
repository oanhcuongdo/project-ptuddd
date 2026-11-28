import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/remote/firebase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/notes/data/datasources/remote/notes_remote_data_source.dart';
import '../../features/notes/data/datasources/remote/supabase_notes_remote_data_source.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/data/repositories/synced_note_repository.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/subjects/data/datasources/remote/supabase_subjects_remote_data_source.dart';
import '../../features/subjects/data/repositories/subject_repository_impl.dart';
import '../../features/subjects/domain/repositories/note_classification_repository.dart';
import '../../features/subjects/domain/repositories/subject_repository.dart';
import '../../features/summary/data/datasources/remote/ai_summary_remote_data_source.dart';
import '../../features/summary/data/repositories/summary_repository_impl.dart';
import '../../features/summary/domain/repositories/summary_repository.dart';
import '../database/app_database.dart';
import '../database/notes_dao.dart';
import '../database/quiz_scores_dao.dart';
import '../database/subjects_dao.dart';
import '../error/failure.dart';
import '../services/ai_client.dart';
import '../sync/sync_status.dart';
import 'note_classification_adapter.dart';

/// Nơi duy nhất khởi tạo database và repository.
///
/// `main.dart` tạo một instance rồi truyền xuống widget tree; test có thể truyền
/// [executor] là `NativeDatabase.memory()` để chạy trong bộ nhớ, [authRepository]
/// là bản giả để không cần Firebase, và [aiClient] là bản giả để không gọi mạng.
class AppDependencies {
  AppDependencies._(
    this._quizScoresDao, {
    required this.database,
    required this.notesDao,
    required this.noteRepository,
    required this.authRepository,
    required this.aiClient,
    required this.summaryRepository,
    required this.syncMonitor,
    required this.syncedNotes,
    required this.accountDatabases,
    required this.syncSession,
    required this.subjectRepository,
    required this.noteClassificationRepository,
  });

  /// [supabaseClient] chỉ khác `null` khi app được chạy kèm
  /// `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`.
  /// Không có client thì ghi chú chỉ lưu trên máy ([NoteRepositoryImpl]) — app
  /// vẫn chạy bình thường và chỉ báo đồng bộ ở trạng thái `disabled`.
  factory AppDependencies.create({
    QueryExecutor? executor,
    AuthRepository? authRepository,
    AiClient? aiClient,
    SupabaseClient? supabaseClient,
    NotesRemoteDataSource? notesRemote,
  }) {
    final database = AppDatabase(executor);
    final notesDao = NotesDao(database);
    final resolvedAuth = authRepository ?? _firebaseAuthRepository();
    final resolvedAiClient =
        aiClient ?? AiClient.fromEnvironment(idTokenProvider: _firebaseIdToken);

    final NotesRemoteDataSource? remote =
        notesRemote ??
        (supabaseClient == null
            ? null
            : SupabaseNotesRemoteDataSource(supabaseClient));
    final SyncMonitor syncMonitor = SyncMonitor(
      initial: remote == null ? SyncStatus.disabled : SyncStatus.syncing,
    );
    final accountDatabases = <String, AppDatabase>{};
    AppDatabase databaseFor(String? uid) => uid == null
        ? database
        : accountDatabases.putIfAbsent(uid, () {
            final suffix = base64Url
                .encode(utf8.encode(uid))
                .replaceAll('=', '');
            return AppDatabase(null, 'smart_note_$suffix');
          });
    final SyncedNoteRepository? syncedNotes = remote == null
        ? null
        : SyncedNoteRepository(
            daoForUser: (uid) => NotesDao(databaseFor(uid)),
            remote: remote,
            currentUserId: () => resolvedAuth.currentUser?.id,
            monitor: syncMonitor,
          );

    final NoteRepository noteRepository =
        syncedNotes ?? NoteRepositoryImpl(notesDao);

    return AppDependencies._(
      () => QuizScoresDao(
        remote == null ? database : databaseFor(resolvedAuth.currentUser?.id),
      ),
      database: database,
      notesDao: notesDao,
      noteRepository: noteRepository,
      authRepository: resolvedAuth,
      aiClient: resolvedAiClient,
      summaryRepository: SummaryRepositoryImpl(
        AiSummaryRemoteDataSourceImpl(resolvedAiClient),
      ),
      syncMonitor: syncMonitor,
      syncedNotes: syncedNotes,
      accountDatabases: accountDatabases,
      syncSession: syncedNotes == null
          ? null
          : resolvedAuth.authStateChanges().listen((_) {
              unawaited(syncedNotes.start());
            }),
      // Môn học (#6) dùng cùng database với ghi chú của tài khoản hiện tại.
      subjectRepository: SubjectRepositoryImpl(
        dao: () => SubjectsDao(
          remote == null ? database : databaseFor(resolvedAuth.currentUser?.id),
        ),
        remote: supabaseClient == null
            ? null
            : SupabaseSubjectsRemoteDataSource(supabaseClient),
        currentUserId: () => resolvedAuth.currentUser?.id,
      ),
      noteClassificationRepository: NoteClassificationAdapter(noteRepository),
    );
  }

  /// Firebase phải được khởi tạo trước ([FirebaseBootstrap.initialize]) thì mới
  /// lấy được `FirebaseAuth.instance`.
  static AuthRepository _firebaseAuthRepository() {
    return AuthRepositoryImpl(FirebaseAuthDataSource(FirebaseAuth.instance));
  }

  /// Gửi kèm token Firebase để máy chủ tóm tắt xác thực người dùng (#12).
  ///
  /// Bản preview (`main_preview.dart`) không khởi tạo Firebase nên trả `null`.
  static Future<String?> _firebaseIdToken() async {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    final user = FirebaseAuth.instance.currentUser;
    try {
      return await user?.getIdToken();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'network-request-failed') {
        throw const AiFailure(
          'Không lấy được phiên đăng nhập. Kiểm tra mạng rồi thử lại.',
          kind: AiFailureKind.network,
        );
      }
      throw const AiFailure(
        'Phiên đăng nhập đã hết hạn. Đăng nhập lại rồi thử lại.',
        kind: AiFailureKind.unauthorized,
      );
    }
  }

  final AppDatabase database;
  final NotesDao notesDao;
  final NoteRepository noteRepository;
  final AuthRepository authRepository;
  final QuizScoresDao Function() _quizScoresDao;
  QuizScoresDao get quizScoresDao => _quizScoresDao();
  final AiClient aiClient;
  final SummaryRepository summaryRepository;

  /// Trạng thái đồng bộ đa thiết bị (#21) — `presentation` chỉ nghe, không tự đoán.
  final SyncMonitor syncMonitor;

  /// Khác `null` khi app đồng bộ với Supabase (dùng để đóng realtime).
  final SyncedNoteRepository? syncedNotes;

  final Map<String, AppDatabase> accountDatabases;
  final StreamSubscription<AppUser?>? syncSession;
  final SubjectRepository subjectRepository;
  final NoteClassificationRepository noteClassificationRepository;

  Future<void> dispose() async {
    aiClient.close();
    await syncSession?.cancel();
    await syncedNotes?.dispose();
    for (final cache in accountDatabases.values) {
      await cache.close();
    }
    await syncMonitor.dispose();
    await database.close();
  }
}
