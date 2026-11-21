import 'package:english_pronunciation_app/ui/goal_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<int>> pump(WidgetTester tester, {int minutes = 10}) async {
    final commits = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GoalSlider(minutes: minutes, onCommit: commits.add))));
    return commits;
  }

  testWidgets('hiện giá trị hiện tại', (tester) async {
    await pump(tester, minutes: 25);
    expect(find.text('25 phút'), findsOneWidget);
  });

  testWidgets('kéo thanh chỉ commit một lần khi thả tay', (tester) async {
    final commits = await pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(Slider)));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
    }
    expect(commits, isEmpty, reason: 'đang kéo thì chưa ghi gì');
    await gesture.up();
    await tester.pump();
    expect(commits, hasLength(1));
    expect(commits.single, greaterThan(10));
    expect(find.text('${commits.single} phút'), findsOneWidget);
  });

  testWidgets('giá trị từ bên ngoài đổi thì thanh cập nhật theo', (tester) async {
    final commits = <int>[];
    Widget app(int m) => MaterialApp(
        home: Scaffold(body: GoalSlider(minutes: m, onCommit: commits.add)));
    await tester.pumpWidget(app(10));
    await tester.pumpWidget(app(40));
    expect(find.text('40 phút'), findsOneWidget);
    expect(commits, isEmpty);
  });
}
