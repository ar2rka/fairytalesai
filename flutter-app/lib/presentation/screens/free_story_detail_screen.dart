import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/free_story.dart';
import '../../domain/entities/free_story_reaction.dart';
import '../theme/app_theme.dart';
import '../widgets/white_card.dart';
import '../widgets/gradient_card.dart';
import '../widgets/font_size_selector.dart';
import '../providers/use_cases_provider.dart';
import '../providers/font_size_provider.dart';

class FreeStoryDetailScreen extends ConsumerStatefulWidget {
  final FreeStory story;

  const FreeStoryDetailScreen({
    super.key,
    required this.story,
  });

  @override
  ConsumerState<FreeStoryDetailScreen> createState() =>
      _FreeStoryDetailScreenState();
}

class _FreeStoryDetailScreenState extends ConsumerState<FreeStoryDetailScreen> {
  FreeStoryReactionStats? _reactionStats;
  bool _isLoadingStats = true;
  bool _isReacting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReactionStats();
    });
  }

  Future<void> _loadReactionStats() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final useCase = ref.read(getFreeStoryReactionStatsUseCaseProvider);
      final stats = await useCase.execute(widget.story.id);
      if (mounted) {
        setState(() {
          _reactionStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки оценок: $e'),
            backgroundColor: Colors.red.shade300,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleReaction(ReactionType reactionType) async {
    if (_isReacting) return;

    setState(() {
      _isReacting = true;
    });

    try {
      final currentReaction = _reactionStats?.userReactionEnum;

      // Если пользователь нажимает на ту же реакцию, удаляем её
      if (currentReaction == reactionType) {
        final removeUseCase = ref.read(removeFreeStoryReactionUseCaseProvider);
        await removeUseCase.execute(widget.story.id);
      } else {
        // Иначе устанавливаем новую реакцию
        final setUseCase = ref.read(setFreeStoryReactionUseCaseProvider);
        await setUseCase.execute(
          freeStoryId: widget.story.id,
          reactionType: reactionType,
        );
      }

      // Перезагружаем статистику
      await _loadReactionStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при оценке: $e'),
            backgroundColor: Colors.red.shade300,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReacting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(storyFontSizeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(widget.story.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          FontSizeSelector(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                gradientColors: AppTheme.gradientPurple,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.story.title,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.story.ageCategoryDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              WhiteCard(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.story.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: fontSize,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              // Reactions Section
              WhiteCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Оцените историю',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingStats)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Like Button
                          _buildReactionButton(
                            context,
                            icon: Icons.thumb_up,
                            label: 'Нравится',
                            count: _reactionStats?.likesCount ?? 0,
                            isSelected: _reactionStats?.userReactionEnum ==
                                ReactionType.like,
                            isDislike: false,
                            onTap: () => _handleReaction(ReactionType.like),
                          ),
                          const SizedBox(width: 24),
                          // Dislike Button
                          _buildReactionButton(
                            context,
                            icon: Icons.thumb_down,
                            label: 'Не нравится',
                            count: _reactionStats?.dislikesCount ?? 0,
                            isSelected: _reactionStats?.userReactionEnum ==
                                ReactionType.dislike,
                            isDislike: true,
                            onTap: () => _handleReaction(ReactionType.dislike),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
    required bool isDislike,
    required VoidCallback onTap,
  }) {
    final backgroundColor = isSelected
        ? (isDislike
            ? AppTheme.gradientPink.first
            : AppTheme.gradientGreen.first)
        : AppTheme.backgroundLight;

    return GestureDetector(
      onTap: _isReacting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDislike
                    ? AppTheme.gradientPink.first
                    : AppTheme.gradientGreen.first)
                : AppTheme.textSecondary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDislike
                            ? AppTheme.gradientPink.first
                            : AppTheme.gradientGreen.first)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDislike
                      ? AppTheme.gradientPink.first
                      : AppTheme.gradientGreen.first),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDislike
                        ? AppTheme.gradientPink.first
                        : AppTheme.gradientGreen.first),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
