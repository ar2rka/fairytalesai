import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_card.dart';

class WelcomeOnboardingPage extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomeOnboardingPage({
    super.key,
    required this.onNext,
  });

  @override
  State<WelcomeOnboardingPage> createState() => _WelcomeOnboardingPageState();
}

class _WelcomeOnboardingPageState extends State<WelcomeOnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _descriptionFadeAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
          milliseconds: 1000), // Увеличено для более плавной анимации
      vsync: this,
    );

    // Scale + Bounce - игривые пружинящие анимации
    // Иконка появляется с bounce эффектом
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

    // Заголовок появляется с fade и slide (после иконки)
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeIn),
      ),
    );
    _titleSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );

    // Описание появляется с fade (после заголовка)
    _descriptionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

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
              return Transform.scale(
                scale: _cardScaleAnimation.value,
                child: Opacity(
                  opacity: _cardFadeAnimation.value,
                  child: GradientCard(
                    gradientColors: AppTheme.gradientPurple,
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: const Icon(
                            Icons.auto_stories,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Transform.translate(
                          offset: Offset(0, _titleSlideAnimation.value),
                          child: Opacity(
                            opacity: _titleFadeAnimation.value,
                            child: Text(
                              'Добро пожаловать в Tale Generator!',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: _descriptionFadeAnimation.value,
                          child: Text(
                            'Создавайте персонализированные сказки для ваших детей с помощью AI',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
