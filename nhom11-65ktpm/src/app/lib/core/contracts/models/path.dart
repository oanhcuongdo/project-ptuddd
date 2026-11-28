
// Model bản đồ lộ trình học.
//
// Quy tắc:
// - Điểm >= 70: hoàn thành.
// - Điểm >= 85: 2 sao.
// - Điểm >= 95: 3 sao.
// - Node đầu tiên luôn mở.
// - Node tiếp theo mở khi node trước hoàn thành.

const double kPassScore = 70.0;

enum NodeStatus {
  locked,
  available,
  completed,
}

class PathNode {
  final int id;
  final String title;
  final int order;
  final int? lessonId;
  final NodeStatus status;
  final double? bestScore;
  final int stars;
  final int xpReward;

  const PathNode({
    required this.id,
    required this.title,
    required this.order,
    this.lessonId,
    this.status = NodeStatus.locked,
    this.bestScore,
    this.stars = 0,
    this.xpReward = 20,
  });

  PathNode copyWith({
    NodeStatus? status,
    double? bestScore,
    int? stars,
  }) {
    return PathNode(
      id: id,
      title: title,
      order: order,
      lessonId: lessonId,
      status: status ?? this.status,
      bestScore: bestScore ?? this.bestScore,
      stars: stars ?? this.stars,
      xpReward: xpReward,
    );
  }
}

class PathStage {
  final int id;
  final String title;
  final int order;
  final String? level;
  final List<PathNode> nodes;

  const PathStage({
  required this.id,
  required this.title,
  required this.order,
  this.level,
  required this.nodes,
  });
}

class PathMap {
  final List<PathStage> stages;
  final int? nextNodeId;
  final int totalNodes;
  final int completedNodes;

  const PathMap({
    required this.stages,
    required this.nextNodeId,
    required this.totalNodes,
    required this.completedNodes,
  });

  /// Node đầu tiên đang mở để người học tiếp tục.
  PathNode? nextNode() {
    for (final stage in stages) {
      for (final node in stage.nodes) {
        if (node.id == nextNodeId) return node;
      }
    }
    return null;
  }
}

int starsForScore(double? score) {
  if (score == null || score < kPassScore) return 0;
  if (score >= 95) return 3;
  if (score >= 85) return 2;
  return 1;
}

PathMap buildPathMap(
  List<PathStage> stages,
  Map<int, double> bestScores,
) {
  final sortedStages = [...stages]
    ..sort((a, b) => a.order.compareTo(b.order));

  var previousCompleted = true;
  int? nextId;
  var totalNodes = 0;
  var completedNodes = 0;

  final resultStages = <PathStage>[];

  for (final stage in sortedStages) {
    final sortedNodes = [...stage.nodes]
      ..sort((a, b) => a.order.compareTo(b.order));

    final resultNodes = <PathNode>[];

    for (final node in sortedNodes) {
      totalNodes++;

      final score = bestScores[node.id];
      final completed = score != null && score >= kPassScore;

      final NodeStatus status;

      if (completed) {
        status = NodeStatus.completed;
        completedNodes++;
      } else if (previousCompleted) {
        status = NodeStatus.available;
        nextId ??= node.id;
      } else {
        status = NodeStatus.locked;
      }

      resultNodes.add(
        node.copyWith(
          status: status,
          bestScore: score,
          stars: starsForScore(score),
        ),
      );

      previousCompleted = completed;
    }

    resultStages.add(
      PathStage(
        id: stage.id,
        title: stage.title,
        order: stage.order,
        level: stage.level,
        nodes: resultNodes,
      ),
    );
  }

  return PathMap(
    stages: resultStages,
    nextNodeId: nextId,
    totalNodes: totalNodes,
    completedNodes: completedNodes,
  );
}
