import 'package:flutter/material.dart';

import '../../../../core/contracts/models/path.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

class RoadmapStageMap extends StatefulWidget {
  final PathStage stage;
  final ValueChanged<PathNode> onNodeTap;

  const RoadmapStageMap({
    super.key,
    required this.stage,
    required this.onNodeTap,
  });

  @override
  State<RoadmapStageMap> createState() => _RoadmapStageMapState();
}

class _RoadmapStageMapState extends State<RoadmapStageMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.stage.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ...widget.stage.nodes.asMap().entries.map((entry) {
              final index = entry.key;
              final node = entry.value;
              return _buildNode(context, node, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(BuildContext context, PathNode node, int index) {
    final isLeft = index.isEven;
    final color = _nodeColor(node.status);
    final isAvailable = node.status == NodeStatus.available;

    final button = InkWell(
      onTap: () => widget.onNodeTap(node),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        child: Icon(
          _nodeIcon(node.status),
          color: Colors.white,
          size: 30,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeft) const Spacer(),
          Column(
            children: [
              if (isAvailable)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: button,
                )
              else
                button,
              const SizedBox(height: 6),
              Text(
                node.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (node.status == NodeStatus.completed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: i < node.stars
                          ? AppColors.warningOrange
                          : AppColors.dividerLight,
                    ),
                  ),
                ),
            ],
          ),
          if (isLeft) const Spacer(),
        ],
      ),
    );
  }

  Color _nodeColor(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return AppColors.jadeGreen;
      case NodeStatus.available:
        return AppColors.infoBlue;
      case NodeStatus.locked:
        return AppColors.cloud;
    }
  }

  IconData _nodeIcon(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return Icons.check_rounded;
      case NodeStatus.available:
        return Icons.play_arrow_rounded;
      case NodeStatus.locked:
        return Icons.lock_rounded;
    }
  }
}
