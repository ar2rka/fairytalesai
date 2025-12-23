import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/value_objects/gender.dart';
import '../../../domain/value_objects/age_category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/white_card.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/age_category_selector.dart';

class AddChildOnboardingPage extends ConsumerStatefulWidget {
  final Function(String name, AgeCategory ageCategory, Gender gender) onNext;
  final Function(bool Function())? onValidateReady;

  const AddChildOnboardingPage({
    super.key,
    required this.onNext,
    this.onValidateReady,
  });

  @override
  ConsumerState<AddChildOnboardingPage> createState() =>
      _AddChildOnboardingPageState();
}

class _AddChildOnboardingPageState extends ConsumerState<AddChildOnboardingPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Gender _gender = Gender.male;
  AgeCategory? _ageCategory;
  late AnimationController _controller;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<double> _formSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
          milliseconds: 1200), // Увеличено для более плавной анимации
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

    // Форма появляется с fade и slide (после карточки)
    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _formSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Регистрируем функцию валидации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValidateReady?.call(validateAndProceed);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool validateAndProceed() {
    if (!_formKey.currentState!.validate()) return false;
    if (_ageCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите возрастную категорию'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    // Передаем данные ребенка на следующую страницу
    widget.onNext(_nameController.text, _ageCategory!, _gender);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Form(
            key: _formKey,
            child: Column(
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
                              Icons.child_care,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Добавьте первого ребенка',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Transform.translate(
                  offset: Offset(0, _formSlideAnimation.value),
                  child: Opacity(
                    opacity: _formFadeAnimation.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        Text(
                          'Имя',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите имя';
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
                          'Пол',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        WhiteCard(
                          padding: const EdgeInsets.all(16),
                          child: SegmentedButton<Gender>(
                            segments: const [
                              ButtonSegment(
                                value: Gender.male,
                                label: Text('Мальчик'),
                                icon: Icon(Icons.male),
                              ),
                              ButtonSegment(
                                value: Gender.female,
                                label: Text('Девочка'),
                                icon: Icon(Icons.female),
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
                      ],
                    ),
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
