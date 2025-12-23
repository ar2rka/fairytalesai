import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/story.dart';
import '../providers/use_cases_provider.dart';
import '../providers/font_size_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/white_card.dart';
import '../widgets/font_size_selector.dart';

class StoryDetailScreen extends ConsumerStatefulWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  ConsumerState<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends ConsumerState<StoryDetailScreen> {
  int? _rating;
  bool _isRating = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.story.rating;
  }

  Future<void> _rateStory(int rating) async {
    if (widget.story.id == null) return;

    setState(() {
      _isRating = true;
    });

    try {
      final useCase = ref.read(rateStoryUseCaseProvider);
      await useCase.execute(widget.story.id!, rating);
      setState(() {
        _rating = rating;
        _isRating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rating saved'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(storyFontSizeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: const [
              FontSizeSelector(),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.gradientPurple,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.story.title,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        if (widget.story.summary != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.story.summary!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Story Content
                  WhiteCard(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.story.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.8,
                            fontSize: fontSize,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Rating Section
                  WhiteCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _rating != null ? 'Your Rating' : 'Rate this story',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (_isRating)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(10, (index) {
                              final starIndex = index + 1;
                              final isFilled =
                                  _rating != null && starIndex <= _rating!;
                              return GestureDetector(
                                onTap: () => _rateStory(starIndex),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    isFilled ? Icons.star : Icons.star_border,
                                    color: isFilled
                                        ? AppTheme.primaryOrange
                                        : AppTheme.textSecondary,
                                    size: 32,
                                  ),
                                ),
                              );
                            }),
                          ),
                        if (_rating != null) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppTheme.gradientOrange,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$_rating / 10',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
