import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/child.dart';
import '../../domain/value_objects/gender.dart';
import '../../domain/value_objects/age_category.dart';
import '../providers/use_cases_provider.dart';
import '../providers/children_provider.dart';
import '../theme/app_theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/gradient_button.dart';
import '../widgets/white_card.dart';
import '../widgets/gradient_card.dart';
import '../widgets/age_category_selector.dart';
import '../widgets/platform_app_bar.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _interestsController = TextEditingController();
  Gender _gender = Gender.male;
  AgeCategory? _ageCategory;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ageCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Пожалуйста, выберите возрастную категорию'),
          backgroundColor: Colors.red.shade300,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
    });

    final interests = _interestsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final child = Child(
      name: _nameController.text,
      ageCategory: _ageCategory!.value,
      gender: _gender.value,
      interests: interests,
    );

    try {
      final useCase = ref.read(createChildUseCaseProvider);
      await useCase.execute(child);
      ref.invalidate(childrenProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.childAddedSuccessfully),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString())),
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: PlatformAppBar(
        title: l10n.addChild,
        leading: PlatformUtils.useCupertino
            ? null // CupertinoNavigationBar автоматически добавляет кнопку назад
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              GradientCard(
                gradientColors: AppTheme.gradientBlue,
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.child_care,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.addAChild,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.createPersonalizedStories,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Name Field
              Text(
                l10n.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.enterChildsName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Age Category Field
              Text(
                'Возрастная категория',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              AgeCategorySelector(
                selectedCategory: _ageCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _ageCategory = category;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Gender
              Text(
                l10n.gender,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              WhiteCard(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<Gender>(
                  segments: [
                    ButtonSegment(
                      value: Gender.male,
                      label: Text(l10n.male),
                      icon: const Icon(Icons.male),
                    ),
                    ButtonSegment(
                      value: Gender.female,
                      label: Text(l10n.female),
                      icon: const Icon(Icons.female),
                    ),
                    ButtonSegment(
                      value: Gender.other,
                      label: Text(l10n.other),
                      icon: const Icon(Icons.person),
                    ),
                  ],
                  selected: {_gender},
                  onSelectionChanged: (Set<Gender> newSelection) {
                    setState(() {
                      _gender = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Interests
              Text(
                l10n.interests,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _interestsController,
                decoration: InputDecoration(
                  labelText: l10n.interestsCommaSeparated,
                  hintText: l10n.interestsExample,
                  prefixIcon: const Icon(Icons.favorite_outline),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              // Save Button
              GradientButton(
                text: l10n.save,
                icon: Icons.check,
                gradientColors: AppTheme.gradientPink,
                isLoading: _isLoading,
                onPressed: _saveChild,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
