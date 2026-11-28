import 'package:chailish/core/contracts/contracts.dart';
import 'package:chailish/features/roadmap/presentation/widgets/roadmap_stage_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // n1: 96 điểm (xong, 3★) · n2: mở · n3: khóa
  final map = buildPathMap(const [
    PathStage(id: 1, title: 'Chặng thử', order: 1, nodes: [
      PathNode(id: 1, title: 'Bài A', order: 1, lessonId: 1),
      PathNode(id: 2, title: 'Bài B', order: 2, lessonId: 2),
      PathNode(id: 3, title: 'Bài C', order: 3, lessonId: 3),
    ]),
  ], const {1: 96});

  Future<void> pumpMap(WidgetTester tester, void Function(PathNode) onTap) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RoadmapStageMap(stage: map.stages.first, onNodeTap: onTap),
        ),
      ),
    ));
  }

  testWidgets('hiển thị đủ 3 trạng thái, 3 sao cho node 96 điểm', (tester) async {
    await pumpMap(tester, (_) {});
    await tester.pump();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.text('Bài A'), findsOneWidget);
  });

  testWidgets('bấm node đang mở gọi onNodeTap với đúng node', (tester) async {
    PathNode? tapped;
    await pumpMap(tester, (n) => tapped = n);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    expect(tapped?.id, 2);
    expect(tapped?.status, NodeStatus.available);
  });
}