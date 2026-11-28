import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/contracts/contracts.dart';
import '../../../../core/widgets/glass.dart';
import '../roadmap_providers.dart';
import '../widgets/roadmap_stage_map.dart';
class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(roadmapProvider);
    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Bản Đồ Lộ Trình HSK')),
      body: Builder(
        builder: (context) {
          final pad = MediaQuery.paddingOf(context);
          return async.when(
            skipLoadingOnReload: true,
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được lộ trình.\n$e',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (map) => ListView(
              padding: EdgeInsets.only(
                top: pad.top + 16,
                bottom: 32,
              ),
              children: [
                for (final stage in map.stages)
                  RoadmapStageMap(
                    stage: stage,
                    onNodeTap: (node) => _onNodeTap(context, node),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  void _onNodeTap(BuildContext context, PathNode node) {
    if (node.status == NodeStatus.locked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Đạt tối thiểu ${kPassScore.toInt()} điểm ở bài trước để mở khóa '
              '"${node.title}"',
            ),
          ),
        );
      return;
    }
    // TODO: khi route của Hoa (#19) có sẵn, đổi thành '/lessons/${node.lessonId}'.
    context.push('/lessons');
  }
}
