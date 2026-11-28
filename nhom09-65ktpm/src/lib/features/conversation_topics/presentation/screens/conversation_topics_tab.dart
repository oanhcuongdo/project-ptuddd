import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/topic_model.dart';
import '../components/topic_card.dart';
import '../components/topics_filter_bar.dart';
import '../components/topics_progress_banner.dart';
import '../components/topics_state_views.dart';
import '../providers/topics_provider.dart';
import '../styles/topics_styles.dart';

/// Màn hình Thư viện Chủ đề & Kịch bản hội thoại tình huống (A1 - B2).
class ConversationTopicsTab extends StatefulWidget {
  final ValueChanged<TopicModel>? onTopicSelected;

  const ConversationTopicsTab({
    super.key,
    this.onTopicSelected,
  });

  @override
  State<ConversationTopicsTab> createState() => _ConversationTopicsTabState();
}

class _ConversationTopicsTabState extends State<ConversationTopicsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().currentProfile?.userId;
      context.read<TopicsProvider>().loadTopics(userId: uid);
    });
  }

  Future<void> _handleRefresh() async {
    final uid = context.read<AuthProvider>().currentProfile?.userId;
    await context
        .read<TopicsProvider>()
        .loadTopics(userId: uid, forceRefresh: true);
  }

  void _handleTopicTap(TopicModel topic) {
    if (widget.onTopicSelected != null) {
      widget.onTopicSelected!(topic);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${topic.thumbnailIcon} ${topic.title} (${topic.level}) — '
            '${topic.starterCount} câu mở đầu, ${topic.dialogueCount} lượt thoại mẫu.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: TopicsStyles.tealDark,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final topicsProvider = context.watch<TopicsProvider>();
    final uid = context.select<AuthProvider, String?>(
      (auth) => auth.currentProfile?.userId,
    );
    final filteredTopics = topicsProvider.filteredTopics;

    return RefreshIndicator(
      color: TopicsStyles.tealPrimary,
      onRefresh: _handleRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final horizontalPadding = maxWidth >= 900 ? 28.0 : 16.0;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TopicsProgressBanner(
                      completedCount: topicsProvider.completedCount,
                      totalCount: topicsProvider.totalCount,
                      progress: topicsProvider.completionProgress,
                      isLoading: topicsProvider.isLoading,
                      onRefresh: _handleRefresh,
                    ),
                    const SizedBox(height: 16),
                    TopicsFilterBar(
                      selectedLevel: topicsProvider.selectedLevel,
                      selectedCategory: topicsProvider.selectedCategory,
                      searchQuery: topicsProvider.searchQuery,
                      showOnlyIncomplete: topicsProvider.showOnlyIncomplete,
                      hasActiveFilters: topicsProvider.hasActiveFilters,
                      availableCategories: topicsProvider.availableCategories,
                      countByLevel: topicsProvider.countByLevel,
                      onLevelChanged: topicsProvider.setLevelFilter,
                      onCategoryChanged: topicsProvider.setCategoryFilter,
                      onSearchChanged: topicsProvider.setSearchQuery,
                      onShowOnlyIncompleteChanged:
                          topicsProvider.setShowOnlyIncomplete,
                      onResetFilters: topicsProvider.resetFilters,
                    ),
                    if (topicsProvider.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      TopicsErrorBanner(
                        message: topicsProvider.errorMessage!,
                        onRetry: _handleRefresh,
                        onDismiss: topicsProvider.clearError,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildResultHeader(
                      filteredCount: filteredTopics.length,
                      totalCount: topicsProvider.totalCount,
                    ),
                    const SizedBox(height: 12),
                    _buildBodyContent(
                      provider: topicsProvider,
                      topics: filteredTopics,
                      userId: uid,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultHeader({
    required int filteredCount,
    required int totalCount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Danh sách chủ đề ($filteredCount/$totalCount)',
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          'Chuẩn khung CEFR A1 – B2',
          style: TopicsStyles.metaText,
        ),
      ],
    );
  }

  Widget _buildBodyContent({
    required TopicsProvider provider,
    required List<TopicModel> topics,
    required String? userId,
  }) {
    if (provider.isLoading && provider.allTopics.isEmpty) {
      return const TopicsLoadingView();
    }

    if (topics.isEmpty) {
      return TopicsEmptyView(
        hasActiveFilters: provider.hasActiveFilters,
        onResetFilters: provider.resetFilters,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final width = constraints.maxWidth;
        final columns = width >= 1020 ? 3 : (width >= 640 ? 2 : 1);
        final cardWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: topics.map((topic) {
            return SizedBox(
              width: cardWidth,
              child: TopicCard(
                topic: topic,
                isUpdating: provider.isUpdatingTopic(topic.id),
                onTap: () => _handleTopicTap(topic),
                onToggleCompleted: () => provider.toggleTopicCompleted(
                  topic.id,
                  userId: userId,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

