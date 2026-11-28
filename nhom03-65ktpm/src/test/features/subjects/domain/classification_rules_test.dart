import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/subjects/domain/entities/subject.dart';
import 'package:smart_note/features/subjects/domain/usecases/classification_rules.dart';

void main() {
  final toan = Subject(
    id: 'toan',
    name: 'Toán',
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );

  group('Tên môn học', () {
    test('bỏ khoảng trắng thừa', () {
      expect(
        ClassificationRules.validateSubjectName('  Ngữ   văn ', <Subject>[
          toan,
        ]),
        'Ngữ văn',
      );
    });

    test('không cho tên trống hoặc quá 40 ký tự', () {
      expect(
        () => ClassificationRules.validateSubjectName('   ', <Subject>[]),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => ClassificationRules.validateSubjectName('a' * 41, <Subject>[]),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('không cho trùng tên, không phân biệt hoa thường', () {
      expect(
        () => ClassificationRules.validateSubjectName('TOÁN', <Subject>[toan]),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.message,
            'message',
            'Môn học "TOÁN" đã có.',
          ),
        ),
      );
    });

    test('đổi tên môn thành chính nó vẫn được', () {
      expect(
        ClassificationRules.validateSubjectName('toán', <Subject>[
          toan,
        ], exceptId: 'toan'),
        'toán',
      );
    });
  });

  group('Tag', () {
    test('bỏ dấu # ở đầu và khoảng trắng thừa', () {
      expect(ClassificationRules.validateTag('  #ôn   thi '), 'ôn thi');
    });

    test('không cho tag trống hoặc chứa dấu phẩy', () {
      expect(
        () => ClassificationRules.validateTag('#'),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => ClassificationRules.validateTag('a,b'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('bỏ tag trùng trong danh sách, giữ thứ tự đầu tiên', () {
      expect(
        ClassificationRules.normalizeTagList(<String>[
          'Ôn thi',
          '#ôn thi',
          'bài tập',
        ]),
        <String>['Ôn thi', 'bài tập'],
      );
    });
  });
}
