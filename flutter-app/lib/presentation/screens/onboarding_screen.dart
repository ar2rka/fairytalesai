import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'main_navigation_screen.dart';
import 'onboarding/welcome_onboarding_page.dart';
import 'onboarding/add_child_onboarding_page.dart';
import 'onboarding/interests_onboarding_page.dart';
import 'onboarding/features_onboarding_page.dart';
import '../../domain/value_objects/gender.dart';
import '../../domain/value_objects/age_category.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/use_cases_provider.dart';
import '../providers/user_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Временное хранение данных ребенка для передачи на страницу интересов
  String? _childName;
  AgeCategory? _childAgeCategory;
  Gender? _childGender;

  // Callback функции для валидации и сохранения
  bool Function()? _validateAddChild;
  Future<bool> Function()? _saveInterests;

  // Количество выбранных интересов
  int _selectedInterestsCount = 0;

  // Анимации для индикаторов
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotWidthAnimations;
  late List<Animation<Color?>> _dotColorAnimations;

  @override
  void initState() {
    super.initState();
    // Инициализируем анимации для точек
    _dotControllers = List.generate(
      _totalPages,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _dotWidthAnimations = _dotControllers.map((controller) {
      return Tween<double>(begin: 8.0, end: 24.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    _dotColorAnimations = _dotControllers.map((controller) {
      return ColorTween(
        begin: AppTheme.primaryPurple.withValues(alpha: 0.3),
        end: AppTheme.primaryPurple,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    // Анимируем первую точку
    _dotControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _handleNextButton() async {
    if (_currentPage == 0) {
      // Страница приветствия - создаем профиль
      await _handleWelcomePageNext();
    } else if (_currentPage == 2) {
      // Страница добавления ребенка - валидируем форму
      if (_validateAddChild != null && _validateAddChild!()) {
        // validateAndProceed уже вызывает _nextPage через onNext
      }
    } else if (_currentPage == 3) {
      // Страница интересов - сохраняем ребенка
      if (_saveInterests != null) {
        await _saveInterests!();
        // saveChild уже вызывает _completeOnboarding через onNext
      }
    } else {
      // Остальные страницы - просто переходим дальше
      _nextPage();
    }
  }

  Future<void> _handleWelcomePageNext() async {
    // Создаем профиль перед переходом на следующую страницу
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Проверяем, есть ли уже профиль
      final getUserProfileUseCase = ref.read(getUserProfileUseCaseProvider);
      final existingProfile = await getUserProfileUseCase.execute();
      if (existingProfile != null) {
        // Профиль уже существует, просто переходим дальше
        _nextPage();
        return;
      }

      // Получаем email пользователя для имени по умолчанию
      final email = Supabase.instance.client.auth.currentUser?.email ?? '';
      final defaultName =
          email.isNotEmpty ? email.split('@').first : 'Пользователь';

      final now = DateTime.now();
      final profile = UserProfile(
        id: userId,
        name: defaultName,
        subscriptionPlan: 'free',
        subscriptionStatus: 'inactive',
        subscriptionStartDate: now,
        subscriptionEndDate: null,
        monthlyStoryCount: 0,
        lastResetDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final useCase = ref.read(createUserProfileUseCaseProvider);
      await useCase.execute(profile);

      // Инвалидируем провайдер профиля
      ref.invalidate(userProfileProvider);

      if (mounted) {
        _nextPage();
      }
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
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      final previousPage = _currentPage;
      _currentPage = page;
      // Сбрасываем счетчик интересов при переходе на другую страницу
      if (page != _totalPages - 1) {
        _selectedInterestsCount = 0;
      }
      // Анимируем точки
      _dotControllers[previousPage].reverse();
      _dotControllers[page].forward();
    });
  }

  void _completeOnboarding() {
    // Переход в главное приложение
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      WelcomeOnboardingPage(onNext: () {
        // Профиль создается автоматически в WelcomeOnboardingPage
        _nextPage();
      }),
      FeaturesOnboardingPage(onNext: () {
        // После просмотра функций переходим к добавлению ребенка
        _nextPage();
      }),
      AddChildOnboardingPage(
        onNext: (name, ageCategory, gender) {
          setState(() {
            _childName = name;
            _childAgeCategory = ageCategory;
            _childGender = gender;
          });
          _nextPage();
        },
        onValidateReady: (validateFn) {
          _validateAddChild = validateFn;
        },
      ),
      _childName != null && _childAgeCategory != null && _childGender != null
          ? InterestsOnboardingPage(
              childName: _childName!,
              childAgeCategory: _childAgeCategory!,
              childGender: _childGender!,
              onNext: _completeOnboarding,
              onSaveReady: (saveFn) {
                _saveInterests = saveFn;
              },
              onSelectionChanged: (count) {
                setState(() {
                  _selectedInterestsCount = count;
                });
              },
            )
          : const Center(child: CircularProgressIndicator()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => _buildAnimatedDot(index),
                ),
              ),
            ),
            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                pageSnapping: true,
                children: _buildPages(),
              ),
            ),
            // Navigation buttons
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: (_currentPage < _totalPages - 1 ||
                      (_currentPage == _totalPages - 1 &&
                          _selectedInterestsCount >= 2))
                  ? Padding(
                      key: const ValueKey('nav-buttons'),
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            AnimatedOpacity(
                              opacity: _currentPage > 0 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: TextButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                  );
                                },
                                child: const Text('Назад'),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          AnimatedScale(
                            scale: 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: GradientButton(
                              text: _currentPage == _totalPages - 1
                                  ? 'Завершить'
                                  : 'Далее',
                              icon: Icons.arrow_forward,
                              gradientColors: AppTheme.gradientPurple,
                              onPressed: () => _handleNextButton(),
                              width: 120,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-nav-buttons')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _dotControllers[index],
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _dotWidthAnimations[index].value,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _dotColorAnimations[index].value,
          ),
        );
      },
    );
  }
}
