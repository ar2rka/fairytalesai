import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/value_objects/story_type.dart';
import '../../domain/value_objects/language.dart';
import '../../domain/value_objects/story_moral.dart';
import '../../domain/value_objects/subscription_plan.dart';
import '../../domain/entities/child.dart';
import '../providers/children_provider.dart';
import '../providers/use_cases_provider.dart';
import '../providers/user_provider.dart';
import '../../application/dto/generate_story_request.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/white_card.dart';
import '../widgets/gradient_card.dart';
import 'story_detail_screen.dart';

class GenerateStoryScreen extends ConsumerStatefulWidget {
  final Child? defaultChild;

  const GenerateStoryScreen({
    super.key,
    this.defaultChild,
  });

  @override
  ConsumerState<GenerateStoryScreen> createState() =>
      _GenerateStoryScreenState();
}

class _GenerateStoryScreenState extends ConsumerState<GenerateStoryScreen> {
  // Константы
  static const double _minStoryLength = 5.0;
  static const double _maxStoryLength = 60.0;
  static const int _sliderDivisions = 55;

  // Состояние формы
  StoryType _storyType = StoryType.child;
  Language _language = Language.english;
  StoryMoral _moral = StoryMoral.kindness;
  Child? _selectedChild;
  double? _storyLength;
  bool _lengthInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.defaultChild;
  }

  void _initializeStoryLength(SubscriptionPlan plan) {
    if (!_lengthInitialized && mounted) {
      setState(() {
        _storyLength = plan.defaultStoryLength;
        _lengthInitialized = true;
      });
    }
  }

  double get _currentStoryLength =>
      _storyLength ?? SubscriptionPlan.free.defaultStoryLength;

  bool get _requiresChild =>
      _storyType == StoryType.child || _storyType == StoryType.combined;

  Future<void> _generateStory() async {
    final l10n = AppLocalizations.of(context)!;

    if (_requiresChild && _selectedChild == null) {
      _showErrorSnackBar(l10n.pleaseSelectAChild);
      return;
    }

    try {
      final request = GenerateStoryRequest(
        storyType: _storyType.value,
        childId: _selectedChild?.id,
        storyLength: _currentStoryLength.toInt(),
        moral: _moral.value,
        language: _language.code,
      );

      final useCase = ref.watch(generateStoryUseCaseProvider);
      final response = await useCase.execute(request);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StoryDetailScreen(story: response.story),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
          AppLocalizations.of(context)!.errorOccurred(e.toString()));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade300,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleStoryTypeChange(StoryType newType) {
    setState(() {
      _storyType = newType;

      // Управляем выбором ребёнка в зависимости от типа истории
      if (widget.defaultChild == null) {
        _selectedChild = null;
      } else if (newType == StoryType.child || newType == StoryType.combined) {
        _selectedChild = widget.defaultChild;
      } else {
        _selectedChild = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    // Инициализация длины истории из тарифа
    if (!_lengthInitialized) {
      userProfileAsync.whenData((userProfile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeStoryLength(userProfile?.plan ?? SubscriptionPlan.free);
        });
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.generateStory),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 32),
              _buildStoryTypeSection(l10n),
              const SizedBox(height: 24),
              _buildLanguageSection(l10n),
              const SizedBox(height: 24),
              _buildMoralSection(l10n),
              const SizedBox(height: 24),
              _buildChildSelectionSection(l10n),
              const SizedBox(height: 24),
              _buildStoryLengthSection(l10n),
              const SizedBox(height: 40),
              _buildGenerateButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return GradientCard(
      gradientColors: AppTheme.gradientBlue,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, size: 48, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.createMagic,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.generateAPersonalizedStory,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTypeSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.storyType, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        WhiteCard(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<StoryType>(
            segments: [
              ButtonSegment(
                value: StoryType.child,
                label: Text(l10n.child),
                icon: const Icon(Icons.child_care),
              ),
              ButtonSegment(
                value: StoryType.hero,
                label: Text(l10n.hero),
                icon: const Icon(Icons.face),
              ),
              ButtonSegment(
                value: StoryType.combined,
                label: Text(l10n.combined),
                icon: const Icon(Icons.people),
              ),
            ],
            selected: {_storyType},
            onSelectionChanged: (newSelection) =>
                _handleStoryTypeChange(newSelection.first),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<Language>(
          initialValue: _language,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.language),
            labelText: l10n.language,
          ),
          items: Language.values
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(lang.displayName),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _language = value);
          },
        ),
      ],
    );
  }

  Widget _buildMoralSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.moral, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<StoryMoral>(
          initialValue: _moral,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.favorite),
            labelText: l10n.moral,
          ),
          items: StoryMoral.values
              .map((moral) => DropdownMenuItem(
                    value: moral,
                    child: Text(moral.translate(_language)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _moral = value);
          },
        ),
      ],
    );
  }

  Widget _buildChildSelectionSection(AppLocalizations l10n) {
    if (!_requiresChild) return const SizedBox.shrink();

    if (widget.defaultChild != null) {
      return _buildDefaultChildInfo(l10n);
    }

    return _buildChildSelector(l10n);
  }

  Widget _buildDefaultChildInfo(AppLocalizations l10n) {
    return WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.child_care, color: AppTheme.primaryPink, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childForStory,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.defaultChild!.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector(AppLocalizations l10n) {
    final childrenAsync = ref.watch(childrenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectChild, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        childrenAsync.when(
          data: (children) => children.isEmpty
              ? _buildNoChildrenMessage(l10n)
              : _buildChildDropdown(children, l10n),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => WhiteCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error: $error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade300,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoChildrenMessage(AppLocalizations l10n) {
    return WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.noChildrenAvailablePleaseAddAChildFirst,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildDropdown(List<Child> children, AppLocalizations l10n) {
    return DropdownButtonFormField<Child>(
      initialValue: _selectedChild,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.child_care),
        labelText: l10n.selectChild,
      ),
      items: children
          .map((child) => DropdownMenuItem(
                value: child,
                child: Text(child.name),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedChild = value),
    );
  }

  Widget _buildStoryLengthSection(AppLocalizations l10n) {
    final minutesLabel = _language == Language.russian ? 'мин' : 'min';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.storyLengthMinutes,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        WhiteCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer,
                      color: AppTheme.primaryPink, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentStoryLength.toInt()} $minutesLabel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: _currentStoryLength,
                min: _minStoryLength,
                max: _maxStoryLength,
                divisions: _sliderDivisions,
                label: '${_currentStoryLength.toInt()}',
                onChanged: (value) {
                  setState(() {
                    _storyLength = value;
                    _lengthInitialized = true;
                  });
                },
                activeColor: AppTheme.primaryPink,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_minStoryLength.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  Text(
                    '${_maxStoryLength.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(AppLocalizations l10n) {
    return GradientButton(
      text: l10n.generateStory,
      icon: Icons.auto_stories,
      gradientColors: AppTheme.gradientPink,
      onPressed: _generateStory,
    );
  }
}
