import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/white_card.dart';

class FeaturesOnboardingPage extends StatefulWidget {
  final VoidCallback onNext;

  const FeaturesOnboardingPage({
    super.key,
    required this.onNext,
  });

  @override
  State<FeaturesOnboardingPage> createState() => _FeaturesOnboardingPageState();
}

class _FeaturesOnboardingPageState extends State<FeaturesOnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardScaleAnimations;
  late List<Animation<double>> _cardFadeAnimations;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _subtitleFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
          milliseconds:
              3500), // Значительно увеличено для очень плавной анимации
      vsync: this,
    );

    // Анимация заголовка - более плавная
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // Анимация подзаголовка - более плавная
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.45, curve: Curves.easeIn),
      ),
    );

    // Scale + Bounce - карточки появляются последовательно с bounce эффектом
    // Значительно увеличенные интервалы для очень плавных анимаций
    // Вычисляем интервалы так, чтобы все поместилось в [0.0, 1.0]
    final cardCount = 3;
    final startPoint = 0.45;
    final duration = 0.4;
    // Вычисляем максимальный шаг, чтобы последняя карточка поместилась
    final maxStep = (1.0 - startPoint - duration) / (cardCount - 1);
    final step = maxStep.clamp(0.0, 0.25); // Ограничиваем шаг для плавности

    _cardScaleAnimations = List.generate(cardCount, (index) {
      final start = (startPoint + (index * step)).clamp(0.0, 1.0);
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

    _cardFadeAnimations = List.generate(cardCount, (index) {
      final start = (startPoint + (index * step)).clamp(0.0, 1.0);
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  Opacity(
                    opacity: _titleFadeAnimation.value,
                    child: Text(
                      'Основные функции',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: _subtitleFadeAnimation.value,
                    child: Text(
                      'Узнайте, что вы можете делать в приложении',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 48),
          Expanded(
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    children: [
                      _buildAnimatedFeatureCard(
                        context,
                        index: 0,
                        icon: Icons.auto_stories,
                        title: 'Генерация сказок',
                        description:
                            'Создавайте персонализированные истории для ваших детей с помощью AI',
                        gradient: AppTheme.gradientPurple,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFeatureCard(
                        context,
                        index: 1,
                        icon: Icons.child_care,
                        title: 'Управление детьми',
                        description:
                            'Добавляйте несколько профилей детей для создания индивидуальных сказок',
                        gradient: AppTheme.gradientPink,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedFeatureCard(
                        context,
                        index: 2,
                        icon: Icons.library_books,
                        title: 'Библиотека сказок',
                        description:
                            'Сохраняйте и просматривайте все созданные истории в удобной библиотеке',
                        gradient: AppTheme.gradientBlue,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFeatureCard(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
  }) {
    return Transform.scale(
      scale: _cardScaleAnimations[index].value,
      child: Opacity(
        opacity: _cardFadeAnimations[index].value,
        child: _buildFeatureCard(
          context,
          icon: icon,
          title: title,
          description: description,
          gradient: gradient,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
  }) {
    return WhiteCard(
      child: Row(
        children: [
          GradientCard(
            gradientColors: gradient,
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
