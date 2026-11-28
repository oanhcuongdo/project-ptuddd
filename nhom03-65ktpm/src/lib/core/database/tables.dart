import 'package:drift/drift.dart';

/// Bảng ghi chú dùng chung cho ghi chú thường và nhật ký hằng ngày.
///
/// `kind` phân biệt hai loại (`note` / `diary`); `deletedAt` cho phép xoá mềm
/// để sau này đồng bộ với Supabase mà không mất dữ liệu.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant(''))();

  TextColumn get content => text().withDefault(const Constant(''))();

  TextColumn get subjectId => text().nullable()();

  /// Danh sách tag lưu dạng chuỗi phân tách bằng dấu phẩy.
  TextColumn get tags => text().withDefault(const Constant(''))();

  /// `note` hoặc `diary`.
  TextColumn get kind => text().withDefault(const Constant('note'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Môn học dùng để phân loại ghi chú (#6), ánh xạ bảng `subjects` của Supabase.
///
/// Ghi chú tham chiếu môn qua `Notes.subjectId`; xoá môn là xoá mềm.
@DataClassName('SubjectRow')
class Subjects extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// Màu hiển thị dạng `#RRGGBB`.
  TextColumn get color => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('QuizScoreRow')
class QuizScores extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();
  TextColumn get noteTitle => text().withDefault(const Constant(''))();
  IntColumn get correctAnswers => integer()();
  IntColumn get totalQuestions => integer()();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
