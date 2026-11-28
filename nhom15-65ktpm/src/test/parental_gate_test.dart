import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/core/constants/app_dimensions.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/domain/entities/verbal_math_question.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/domain/usecases/generate_parental_gate_question.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/domain/usecases/validate_parental_gate_answer.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/widgets/parental_gate_dialog.dart';
import 'package:soroban_kids_app/shared/widgets/kid_button.dart';

class _GateHost extends StatefulWidget {
  const _GateHost();

  @override
  State<_GateHost> createState() => _GateHostState();
}

class _GateHostState extends State<_GateHost> {
  bool _passed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _passed
            ? const Text('Parent Dashboard')
            : ElevatedButton(
                onPressed: () async {
                  final authenticated =
                      await ParentalGateDialog.authenticate(context);
                  if (authenticated && mounted) {
                    setState(() => _passed = true);
                  }
                },
                child: const Text('Open gate'),
              ),
      ),
    );
  }
}

const _numberWords = [
  'không',
  'một',
  'hai',
  'ba',
  'bốn',
  'năm',
  'sáu',
  'bảy',
  'tám',
  'chín',
  'mười',
  'mười một',
  'mười hai',
  'mười ba',
  'mười bốn',
  'mười lăm',
  'mười sáu',
  'mười bảy',
  'mười tám',
  'mười chín',
  'hai mươi',
];

int _answerFromQuestionText(WidgetTester tester) {
  final questionText =
      tester.widget<Text>(find.textContaining('bằng mấy?')).data!;
  return _answerFromText(questionText);
}

int _answerFromText(String questionText) {
  final match = RegExp(r'^(.+) (cộng|trừ) (.+) bằng mấy\?$')
      .firstMatch(questionText.toLowerCase())!;
  final first = _numberWords.indexOf(match.group(1)!);
  final second = _numberWords.indexOf(match.group(3)!);
  return match.group(2) == 'cộng' ? first + second : first - second;
}

List<KidButton> _suggestedAnswerButtons(WidgetTester tester) {
  return tester
      .widgetList<KidButton>(find.byType(KidButton))
      .where((button) => int.tryParse(button.label ?? '') != null)
      .toList();
}

Future<void> _openGate(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: _GateHost()));
  await tester.tap(find.text('Open gate'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const question = VerbalMathQuestion(
    questionText: 'Năm cộng ba bằng mấy?',
    answer: 8,
    options: [6, 8, 9, 11],
  );

  group('ValidateParentalGateAnswer', () {
    const validator = ValidateParentalGateAnswer();

    test('distinguishes empty, invalid, and incorrect answers', () {
      expect(
        validator.validateInput(question: question, input: ' \t '),
        ParentalGateAnswerStatus.empty,
      );
      expect(
        validator.validateInput(question: question, input: 'kem'),
        ParentalGateAnswerStatus.invalid,
      );
      expect(
        validator.validateInput(question: question, input: '7'),
        ParentalGateAnswerStatus.incorrect,
      );
    });

    test('normalizes digits and Vietnamese words', () {
      for (final input in ['8', '  tám  ', 'TÁM', ' TÁM \t']) {
        expect(
          validator.validateInput(question: question, input: input),
          ParentalGateAnswerStatus.correct,
          reason: input,
        );
      }
    });
  });

  test('generated questions vary and keep answer among unique suggestions', () {
    final generator = GenerateParentalGateQuestion(random: Random(42));
    String? previousQuestion;

    for (var index = 0; index < 30; index++) {
      final generated = generator.generate();
      expect(generated.questionText, isNot(previousQuestion));
      expect(generated.answer, _answerFromText(generated.questionText));
      expect(generated.options, hasLength(4));
      expect(generated.options.toSet(), hasLength(4));
      expect(generated.options, contains(generated.answer));
      previousQuestion = generated.questionText;
    }
  });

  testWidgets('empty and incorrect submissions show distinct feedback',
      (tester) async {
    await _openGate(tester);

    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    expect(find.text('Vui lòng nhập hoặc chọn đáp án.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    expect(
        find.text('Kết quả chưa chính xác. Vui lòng thử lại.'), findsOneWidget);
    expect(find.text('Parent Dashboard'), findsNothing);
  });

  testWidgets('typing clears errors, selects matching suggestion, Enter passes',
      (tester) async {
    await _openGate(tester);
    final input = find.byType(TextField);
    final inputWidget = tester.widget<TextField>(input);
    expect(inputWidget.focusNode?.hasFocus, isTrue);

    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    expect(find.text('Vui lòng nhập hoặc chọn đáp án.'), findsOneWidget);

    final answer = _answerFromQuestionText(tester);
    await tester.enterText(input, ' ${_numberWords[answer].toUpperCase()} ');
    await tester.pump();
    expect(find.text('Vui lòng nhập hoặc chọn đáp án.'), findsNothing);
    final answerButton = tester.widget<KidButton>(
      find.widgetWithText(KidButton, '$answer'),
    );
    expect(answerButton.isSelected, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Parent Dashboard'), findsOneWidget);
  });

  testWidgets('selecting a suggested answer synchronizes input and validates',
      (tester) async {
    await _openGate(tester);

    final answer = _answerFromQuestionText(tester);
    await tester.tap(find.text('$answer'));
    await tester.pumpAndSettle();

    expect(find.text('Parent Dashboard'), findsOneWidget);
  });

  testWidgets('each new gate opening presents a different question',
      (tester) async {
    await _openGate(tester);
    final firstQuestion =
        tester.widget<Text>(find.textContaining('bằng mấy?')).data;

    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open gate'));
    await tester.pumpAndSettle();

    final nextQuestion =
        tester.widget<Text>(find.textContaining('bằng mấy?')).data;
    expect(nextQuestion, isNot(firstQuestion));
  });

  testWidgets('wrong selection stays selected and typing clears its error',
      (tester) async {
    await _openGate(tester);

    final answer = _answerFromQuestionText(tester);
    final wrongAnswer = _suggestedAnswerButtons(tester).firstWhere(
      (button) => int.parse(button.label!) != answer,
    );
    final wrongValue = wrongAnswer.label!;
    await tester.tap(find.text(wrongValue));
    await tester.pump();
    expect(
        find.text('Kết quả chưa chính xác. Vui lòng thử lại.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        wrongValue);
    expect(
      tester
          .widget<KidButton>(find.widgetWithText(KidButton, wrongValue))
          .isSelected,
      isTrue,
    );

    await tester.enterText(find.byType(TextField), '$answer');
    await tester.pump();
    expect(
        find.text('Kết quả chưa chính xác. Vui lòng thử lại.'), findsNothing);
    expect(
      tester
          .widget<KidButton>(find.widgetWithText(KidButton, '$answer'))
          .isSelected,
      isTrue,
    );
  });

  testWidgets('barrier, Escape, and system back cannot bypass the gate',
      (tester) async {
    await _openGate(tester);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.byType(ParentalGateDialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ParentalGateDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ParentalGateDialog), findsOneWidget);
    expect(find.text('Parent Dashboard'), findsNothing);
  });

  testWidgets('back button closes without opening the dashboard',
      (tester) async {
    await _openGate(tester);

    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.byType(ParentalGateDialog), findsNothing);
    expect(find.text('Parent Dashboard'), findsNothing);
    expect(find.text('Open gate'), findsOneWidget);
  });

  testWidgets('gate controls retain minimum touch size on a compact viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 320);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await _openGate(tester);

    final options =
        _suggestedAnswerButtons(tester).map((button) => button.label!);
    for (final label in [...options, 'Xác nhận', 'Quay lại']) {
      final button = find.widgetWithText(KidButton, label);
      await tester.ensureVisible(button);
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(AppDimensions.minTouchSize));
      expect(size.height, greaterThanOrEqualTo(AppDimensions.minTouchSize));
    }

    expect(tester.takeException(), isNull);
  });
}
