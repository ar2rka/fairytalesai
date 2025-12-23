import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';

/// Тестовый виджет для прямого доступа к онбордингу
/// Используйте это для тестирования анимаций без необходимости
/// проходить через аутентификацию и проверку профиля
class TestOnboardingWrapper extends StatelessWidget {
  /// Если true - показывает онбординг напрямую
  /// Если false - показывает обычный AuthWrapper
  static const bool showOnboardingDirectly = true;

  const TestOnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (showOnboardingDirectly) {
      return const OnboardingScreen();
    }
    return const AuthScreen();
  }
}
