import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/preview/preview_auth_repository.dart';
import 'core/services/ai_client.dart';
import 'features/notes/domain/entities/note.dart';

/// Entry **chỉ để xem trước giao diện** (không dùng cho bản phát hành):
///
/// ```bash
/// flutter run -t lib/main_preview.dart
/// ```
///
/// Không khởi tạo Firebase, nên chạy được trên máy chưa có
/// `google-services.json`. Đăng nhập bằng bất kỳ email/mật khẩu hợp lệ.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create(
    authRepository: PreviewAuthRepository(),
    // Bản preview không có máy chủ tóm tắt: dùng bản trích câu cục bộ để xem
    // trước màn #12.
    aiClient: AiClient.demo(),
  );
  await _seedPreviewNotes(dependencies);
  runApp(SmartNoteApp(dependencies: dependencies));
}

/// Ghi chú mẫu chỉ tồn tại trong database của bản preview, để thấy đủ dạng
/// thẻ pastel khi review giao diện.
Future<void> _seedPreviewNotes(AppDependencies dependencies) async {
  final existing = await dependencies.noteRepository.getNotes();
  if (existing.isNotEmpty) {
    return;
  }
  final now = DateTime.now();
  final samples = <Note>[
    Note(
      id: 'preview-1',
      title: 'Giải tích – Chương 3',
      content:
          'Đạo hàm, tích phân và ứng dụng. Ôn lại quy tắc chuỗi trước '
          'buổi seminar.',
      kind: NoteKind.note,
      createdAt: now,
      updatedAt: now,
      tags: const <String>['Toán'],
    ),
    Note(
      id: 'preview-2',
      title: 'Vật lý – Điện từ',
      content: 'Định luật Faraday, cảm ứng điện từ. Làm bài tập 4.1 – 4.6.',
      kind: NoteKind.note,
      createdAt: now,
      updatedAt: now.subtract(const Duration(hours: 2)),
      tags: const <String>['Vật lý'],
    ),
    Note(
      id: 'preview-3',
      title: 'Tiếng Anh – Unit 5',
      content: 'Từ vựng chủ đề môi trường, thì hiện tại hoàn thành.',
      kind: NoteKind.note,
      createdAt: now,
      updatedAt: now.subtract(const Duration(hours: 5)),
      tags: const <String>['Tiếng Anh'],
    ),
    Note(
      id: 'preview-4',
      title: 'Sinh học – Tế bào',
      content: 'Cấu trúc tế bào nhân thực, chức năng từng bào quan.',
      kind: NoteKind.note,
      createdAt: now,
      updatedAt: now.subtract(const Duration(days: 1)),
      tags: const <String>['Sinh học'],
    ),
    Note(
      id: 'preview-5',
      title: 'Nhật ký hôm nay',
      content: 'Học xong chương 3, chạy bộ 3 km, ngủ đủ giấc.',
      kind: NoteKind.diary,
      createdAt: now,
      updatedAt: now.subtract(const Duration(days: 1, hours: 3)),
      tags: const <String>['Nhật ký'],
    ),
    Note(
      id: 'preview-6',
      title: 'Lịch sử Việt Nam',
      content: 'Mốc thời gian 1945 – 1954, chuẩn bị thuyết trình nhóm.',
      kind: NoteKind.note,
      createdAt: now,
      updatedAt: now.subtract(const Duration(days: 2)),
      tags: const <String>['Lịch sử'],
    ),
  ];
  for (final note in samples) {
    await dependencies.noteRepository.createNote(note);
  }
}
