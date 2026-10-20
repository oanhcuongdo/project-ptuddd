import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/supabase_config.dart';
import 'database/app_database.dart';
import 'database/connection/connection.dart';
import 'domain/services/document_service.dart';
import 'domain/services/subject_service.dart';
import 'domain/services/backup_restore_service.dart';
import 'domain/services/auth_service.dart';
import 'domain/services/firebase_sync_service.dart';
import 'domain/services/supabase_document_service.dart';
import 'state/document_provider.dart';
import 'state/settings_provider.dart';
import 'state/auth_provider.dart';
import 'state/supabase_provider.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase (Hỗ trợ Google Sign-In)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully!');
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // 2. Khởi tạo Supabase (Quản lý cơ sở dữ liệu quan hệ, Storage & RLS)
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully!');
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  // 3. Khởi tạo Database cục bộ SQLite theo nguyên lý Local-First
  final database = AppDatabase(constructDb());

  // 4. Khởi tạo các Domain Services (Phân tầng logic tách bạch)
  final documentService = DocumentService(
    documentDao: database.documentDao,
    deleteLogDao: database.deleteLogDao,
  );
  final subjectService = SubjectService(
    subjectDao: database.subjectDao,
    deleteLogDao: database.deleteLogDao,
  );
  final backupService = BackupRestoreService(
    documentDao: database.documentDao,
    subjectDao: database.subjectDao,
    deleteLogDao: database.deleteLogDao,
  );
  final authService = AuthService();
  final firebaseSyncService = FirebaseSyncService();
  final supabaseDocService = SupabaseDocumentService();

  // Tạo dữ liệu mẫu ban đầu nếu cơ sở dữ liệu trống
  await _seedInitialDataIfEmpty(subjectService, documentService);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => DocumentProvider(
            documentService: documentService,
            subjectService: subjectService,
            backupRestoreService: backupService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            syncService: firebaseSyncService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SupabaseProvider(service: supabaseDocService),
        ),
      ],
      child: const StudyMaterialApp(),
    ),
  );
}

Future<void> _seedInitialDataIfEmpty(
  SubjectService subjectService,
  DocumentService documentService,
) async {
  final subjects = await subjectService.getAllSubjects();
  if (subjects.isEmpty) {
    final s1 = await subjectService.createSubject(
      code: 'SE310',
      name: 'Kiến trúc Phần mềm',
      lecturer: 'TS. Nguyễn Văn A',
      semester: 'HK1 2026-2027',
      colorHex: '#1E88E5',
    );
    final s2 = await subjectService.createSubject(
      code: 'CS201',
      name: 'Cấu trúc Dữ liệu & Giải thuật',
      lecturer: 'ThS. Trần Thị B',
      semester: 'HK1 2026-2027',
      colorHex: '#43A047',
    );
    final s3 = await subjectService.createSubject(
      code: 'DB302',
      name: 'Hệ Quản trị Cơ sở Dữ liệu',
      lecturer: 'PGS.TS. Lê Hoàng C',
      semester: 'HK1 2026-2027',
      colorHex: '#FB8C00',
    );

    // Seed Documents
    await documentService.createDocument(
      title: 'Bài giảng Chương 1: Tổng quan Kiến trúc Cashew & Local-First',
      subjectFk: s1.subjectPk,
      docType: 'lecture',
      content: 'Nghiên cứu nguyên lý Local-First, cơ sở dữ liệu SQLite nhúng, Drift ORM và giải pháp Zero-Knowledge.',
      priority: 2,
      status: 'completed',
    );

    await documentService.createDocument(
      title: 'Bài tập Thực hành 1: Thiết kế DFD và Phân tầng Mô-đun Quản lý Tài liệu',
      subjectFk: s1.subjectPk,
      docType: 'assignment',
      content: 'Xây dựng sơ đồ luồng dữ liệu DFD Mức 0, DFD Mức 1 và triển khai các tầng Presentation, Logic, Persistence.',
      priority: 2,
      status: 'active',
    );

    await documentService.createDocument(
      title: 'Tài liệu Tham khảo: Drift Persistence Library & Reactive Streams',
      subjectFk: s1.subjectPk,
      docType: 'reference',
      content: 'Tài liệu chính thức drift.simonbinder.eu hướng dẫn cách cấu hình Streams, DAOs và Tombstone DeleteLogs.',
      fileUrl: 'https://drift.simonbinder.eu/docs/',
      priority: 1,
      status: 'completed',
    );

    await documentService.createDocument(
      title: 'Bài tập Lớn: Cài đặt Cây AVL và B-Tree trong Bộ nhớ Ngoài',
      subjectFk: s2.subjectPk,
      docType: 'assignment',
      content: 'Mô phỏng cơ chế phân trang đĩa và tối ưu hóa số lần I/O đọc ghi tương tự SQLite B-Tree.',
      priority: 1,
      status: 'active',
    );

    await documentService.createDocument(
      title: 'Đề cương Ôn thi: Lý thuyết ACID & Chuẩn hóa Cơ sở Dữ liệu Quan hệ',
      subjectFk: s3.subjectPk,
      docType: 'reference',
      content: 'Tổng hợp các dạng bài tập chuẩn hóa 1NF, 2NF, 3NF, BCNF và cơ chế giao tác SQLite WAL.',
      priority: 2,
      status: 'active',
    );
  }
}

class StudyMaterialApp extends StatelessWidget {
  const StudyMaterialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Quản lý Tài liệu Học tập - Kiến trúc Cashew',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
