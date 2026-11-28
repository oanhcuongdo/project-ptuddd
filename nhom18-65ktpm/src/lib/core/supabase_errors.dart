import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

/// Chạy một lệnh gọi Supabase, đổi lỗi thành [AppException] có message tiếng Việt.
/// Lỗi lập trình (Error) vẫn được ném nguyên để không che bug.
Future<T> guardSupabase<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on AppException {
    rethrow;
  } on PostgrestException catch (e) {
    throw AppException(postgrestMessage(e));
  } on StorageException catch (e) {
    throw AppException('Không thể tải tệp lên: ${e.message}');
  } on Exception {
    throw const AppException('Không thể kết nối mạng, vui lòng thử lại sau.');
  }
}

String postgrestMessage(PostgrestException e) {
  switch (e.code) {
    // raise exception trong RPC: message đã là câu hiển thị cho người dùng.
    case 'P0001':
      return e.message;
    case '42501':
      return 'Bạn không có quyền thực hiện thao tác này.';
    case '23505':
      return 'Dữ liệu đã tồn tại.';
    case '23514':
      return 'Dữ liệu không hợp lệ.';
  }
  return e.message;
}
