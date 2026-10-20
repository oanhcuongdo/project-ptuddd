import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:provider/provider.dart';
import 'package:study_material_manager/database/app_database.dart';
import 'package:study_material_manager/domain/services/document_service.dart';
import 'package:study_material_manager/domain/services/subject_service.dart';
import 'package:study_material_manager/domain/services/backup_restore_service.dart';
import 'package:study_material_manager/state/document_provider.dart';
import 'package:study_material_manager/state/settings_provider.dart';
import 'package:study_material_manager/state/auth_provider.dart';
import 'package:study_material_manager/state/supabase_provider.dart';
import 'package:study_material_manager/main.dart';

void main() {
  testWidgets('Khởi chạy ứng dụng và hiển thị thanh điều hướng chính', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final docService = DocumentService(documentDao: db.documentDao, deleteLogDao: db.deleteLogDao);
    final subjService = SubjectService(subjectDao: db.subjectDao, deleteLogDao: db.deleteLogDao);
    final backupService = BackupRestoreService(
      documentDao: db.documentDao,
      subjectDao: db.subjectDao,
      deleteLogDao: db.deleteLogDao,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: db),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SupabaseProvider()),
          ChangeNotifierProvider(
            create: (_) => DocumentProvider(
              documentService: docService,
              subjectService: subjService,
              backupRestoreService: backupService,
            ),
          ),
        ],
        child: const StudyMaterialApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Kiểm tra các nhãn điều hướng của 5 Tab xuất hiện
    expect(find.text('Tài liệu'), findsWidgets);
    expect(find.text('Môn học'), findsWidgets);
    expect(find.text('Cloud RLS'), findsWidgets);
    expect(find.text('Thống kê'), findsWidgets);
    expect(find.text('Cài đặt'), findsWidgets);

    await db.close();
  });
}
