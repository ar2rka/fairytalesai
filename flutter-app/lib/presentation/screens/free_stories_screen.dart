import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/free_story.dart';
import '../providers/free_stories_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_card.dart';
import '../widgets/white_card.dart';
import 'free_story_detail_screen.dart';

class FreeStoriesScreen extends ConsumerStatefulWidget {
  const FreeStoriesScreen({super.key});

  @override
  ConsumerState<FreeStoriesScreen> createState() => _FreeStoriesScreenState();
}

class _FreeStoriesScreenState extends ConsumerState<FreeStoriesScreen> {
  String? _selectedAgeCategory;
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final currentLanguage = locale.languageCode;

    // Используем текущий язык по умолчанию, если не выбран
    final language = _selectedLanguage ?? currentLanguage;
    final params = FreeStoriesParams(
      ageCategory: _selectedAgeCategory,
      language: language,
    );
    final freeStoriesAsync = ref.watch(freeStoriesProvider(params));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.freeStories,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.browseFreeStories,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterChip(
                      context,
                      label: l10n.ageCategory,
                      value: _selectedAgeCategory,
                      options: const ['2-3', '3-5', '5-7'],
                      onSelected: (value) {
                        setState(() {
                          _selectedAgeCategory =
                              _selectedAgeCategory == value ? null : value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Body
            Expanded(
              child: freeStoriesAsync.when(
                data: (stories) => _buildStoriesList(context, stories, l10n),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.somethingWentWrong,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(
                            freeStoriesProvider(params),
                          ),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      children: [
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ...options.map((option) {
          final isSelected = value == option;
          return FilterChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (selected) {
              onSelected(selected ? option : null);
            },
            selectedColor: AppTheme.primaryPurple,
            checkmarkColor: Colors.white,
          );
        }),
        if (value != null)
          FilterChip(
            label: const Text('Все'),
            selected: false,
            onSelected: (_) => onSelected(null),
          ),
      ],
    );
  }

  Widget _buildStoriesList(
    BuildContext context,
    List<FreeStory> stories,
    AppLocalizations l10n,
  ) {
    if (stories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GradientCard(
                gradientColors: AppTheme.gradientPurple,
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_stories,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noFreeStoriesFound,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tryDifferentFilters,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(freeStoriesProvider(
          FreeStoriesParams(
            ageCategory: _selectedAgeCategory,
            language: _selectedLanguage,
          ),
        ));
      },
      color: AppTheme.primaryPurple,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final gradients = [
            AppTheme.gradientPurple,
            AppTheme.gradientPink,
            AppTheme.gradientBlue,
            AppTheme.gradientOrange,
            AppTheme.gradientGreen,
          ];
          final gradient = gradients[index % gradients.length];

          return WhiteCard(
            margin: const EdgeInsets.only(bottom: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FreeStoryDetailScreen(story: story),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            story.content.length > 150
                                ? '${story.content.substring(0, 150)}...'
                                : story.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        story.ageCategoryDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

