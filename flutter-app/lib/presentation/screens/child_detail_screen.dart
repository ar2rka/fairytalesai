import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/child.dart';
import '../../domain/value_objects/gender.dart';
import '../../domain/value_objects/language.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_card.dart';
import '../widgets/white_card.dart';
import '../widgets/gradient_button.dart';
import 'generate_story_screen.dart';

class ChildDetailScreen extends ConsumerWidget {
  final Child child;

  const ChildDetailScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradients = [
      AppTheme.gradientPurple,
      AppTheme.gradientPink,
      AppTheme.gradientBlue,
      AppTheme.gradientOrange,
      AppTheme.gradientGreen,
    ];
    final gradient = gradients[child.name.hashCode.abs() % gradients.length];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Профиль ребёнка'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Avatar
            GradientCard(
              gradientColors: gradient,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        child.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    child.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    child.ageCategoryEnum.displayLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Info Cards
            WhiteCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: gradient.first,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Информация',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    context,
                    'Имя',
                    child.name,
                    Icons.person_outline,
                    gradient.first,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    'Возрастная категория',
                    child.ageCategoryEnum.displayLabel,
                    Icons.cake_outlined,
                    gradient.first,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    'Пол',
                    child.genderEnum.translate(Language.russian),
                    child.genderEnum == Gender.male ? Icons.male : Icons.female,
                    gradient.first,
                  ),
                ],
              ),
            ),
            if (child.interests.isNotEmpty) ...[
              const SizedBox(height: 16),
              WhiteCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_outline,
                          color: gradient.first,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Интересы',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: child.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradient),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Generate Story Button
            GradientButton(
              text: 'Сгенерировать историю',
              icon: Icons.auto_stories,
              gradientColors: AppTheme.gradientPink,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenerateStoryScreen(
                      defaultChild: child,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
