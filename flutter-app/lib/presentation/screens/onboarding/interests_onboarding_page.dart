import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/child.dart';
import '../../../domain/value_objects/gender.dart';
import '../../../domain/value_objects/age_category.dart';
import '../../providers/use_cases_provider.dart';
import '../../providers/children_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/white_card.dart';

class InterestsOnboardingPage extends ConsumerStatefulWidget {
  final String childName;
  final AgeCategory childAgeCategory;
  final Gender childGender;
  final VoidCallback onNext;
  final Function(Future<bool> Function())? onSaveReady;
  final Function(int)? onSelectionChanged;

  const InterestsOnboardingPage({
    super.key,
    required this.childName,
    required this.childAgeCategory,
    required this.childGender,
    required this.onNext,
    this.onSaveReady,
    this.onSelectionChanged,
  });

  @override
  ConsumerState<InterestsOnboardingPage> createState() =>
      _InterestsOnboardingPageState();
}

class _InterestsOnboardingPageState
    extends ConsumerState<InterestsOnboardingPage>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedInterests = {};
  String? _validationError;
  late AnimationController _controller;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _iconScaleAnimation;
  late List<Animation<double>> _checkboxScaleAnimations;
  late List<Animation<double>> _checkboxFadeAnimations;

  // Списки интересов в зависимости от пола
  static const List<String> _maleInterests = [
    'Спорт',
    'Конструкторы',
    'Машинки',
    'Роботы',
    'Приключения',
    'Наука',
  ];

  static const List<String> _femaleInterests = [
    'Куклы',
    'Рисование',
    'Музыка',
    'Танцы',
    'Принцессы',
    'Животные',
  ];

  List<String> get _availableInterests {
    return widget.childGender == Gender.male
        ? _maleInterests
        : _femaleInterests;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
          milliseconds: 1400), // Увеличено для более плавной анимации
      vsync: this,
    );

    // Scale + Bounce - игривые пружинящие анимации
    // Иконка появляется с bounce
    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );

    // Карточка появляется с scale и fade
    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );

    // Чекбоксы появляются последовательно с bounce эффектом
    final interestCount = _availableInterests.length;
    // Вычисляем шаг так, чтобы последний элемент заканчивался на 1.0
    // Увеличена начальная точка и шаг для более плавной анимации
    final step = (1.0 - 0.55) / interestCount;
    final duration = 0.3; // Увеличена длительность каждой анимации

    _checkboxScaleAnimations = List.generate(interestCount, (index) {
      final start = 0.55 + (index * step);
      final end = (start + duration).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            start,
            end,
            curve: Curves.elasticOut,
          ),
        ),
      );
    });

    _checkboxFadeAnimations = List.generate(interestCount, (index) {
      final start = 0.55 + (index * step);
      final end = (start + duration).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            start,
            end,
            curve: Curves.easeIn,
          ),
        ),
      );
    });

    _controller.forward();

    // Регистрируем функцию сохранения и обновляем счетчик выбранных интересов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSaveReady?.call(saveChild);
      widget.onSelectionChanged?.call(_selectedInterests.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _validateSelection() {
    if (_selectedInterests.length < 2) {
      setState(() {
        _validationError = 'Выберите минимум 2 интереса';
      });
      return false;
    }
    setState(() {
      _validationError = null;
    });
    return true;
  }

  Future<bool> saveChild() async {
    if (!_validateSelection()) {
      return false;
    }

    final child = Child(
      name: widget.childName,
      ageCategory: widget.childAgeCategory.value,
      gender: widget.childGender.value,
      interests: _selectedInterests.toList(),
    );

    try {
      final useCase = ref.read(createChildUseCaseProvider);
      await useCase.execute(child);
      ref.invalidate(childrenProvider);
      if (mounted) {
        widget.onNext();
        return true;
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red.shade300,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: _cardScaleAnimation.value,
                child: Opacity(
                  opacity: _cardFadeAnimation.value,
                  child: GradientCard(
                    gradientColors: AppTheme.gradientBlue,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: const Icon(
                            Icons.favorite,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Интересы ${widget.childName}',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Расскажите о том, что нравится вашему ребенку',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Interests Selection
              Text(
                'Интересы',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите минимум 2 интереса',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              WhiteCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _availableInterests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final interest = entry.value;
                    return Transform.scale(
                      scale: _checkboxScaleAnimations[index].value,
                      child: Opacity(
                        opacity: _checkboxFadeAnimations[index].value,
                        child: CheckboxListTile(
                          title: Text(interest),
                          value: _selectedInterests.contains(interest),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                              _validationError =
                                  null; // Сбрасываем ошибку при изменении
                              // Уведомляем родительский виджет об изменении количества выбранных интересов
                              widget.onSelectionChanged
                                  ?.call(_selectedInterests.length);
                            });
                          },
                          activeColor: AppTheme.primaryBlue,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _validationError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
