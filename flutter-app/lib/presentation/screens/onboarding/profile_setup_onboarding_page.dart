import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/gradient_button.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/use_cases_provider.dart';
import '../../providers/user_provider.dart';

class ProfileSetupOnboardingPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const ProfileSetupOnboardingPage({
    super.key,
    required this.onNext,
  });

  @override
  ConsumerState<ProfileSetupOnboardingPage> createState() =>
      _ProfileSetupOnboardingPageState();
}

class _ProfileSetupOnboardingPageState
    extends ConsumerState<ProfileSetupOnboardingPage> {
  bool _isLoading = false;

  Future<void> _createProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Получаем email пользователя для имени по умолчанию
      final email = Supabase.instance.client.auth.currentUser?.email ?? '';
      final defaultName = email.isNotEmpty 
          ? email.split('@').first 
          : 'Пользователь';

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

      // Инвалидируем провайдер профиля, чтобы AuthWrapper обновился
      ref.invalidate(userProfileProvider);

      if (mounted) {
        widget.onNext();
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GradientCard(
            gradientColors: AppTheme.gradientPink,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(
                  Icons.person_add,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Добро пожаловать!',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Давайте настроим ваш профиль',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          GradientButton(
            text: 'Продолжить',
            icon: Icons.arrow_forward,
            gradientColors: AppTheme.gradientPink,
            isLoading: _isLoading,
            onPressed: _createProfile,
          ),
        ],
      ),
    );
  }
}
