import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/font_size_provider.dart';
import '../theme/app_theme.dart';
import '../utils/platform_utils.dart';

class FontSizeSelector extends ConsumerWidget {
  const FontSizeSelector({super.key});

  void _showFontSizeBottomSheet(BuildContext context, WidgetRef ref) {
    if (PlatformUtils.useCupertino) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            bottom: 32,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.placeholderText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Размер шрифта',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildContent(context, ref),
              ],
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Text(
                'Размер шрифта',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _buildContent(context, ref),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final currentSize = ref.watch(storyFontSizeProvider);
        final notifier = ref.read(storyFontSizeProvider.notifier);

        if (PlatformUtils.useCupertino) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Current size display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppTheme.gradientPurple,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${currentSize.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'pt',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Decrease button
                Row(
                  children: [
                    Expanded(
                      child: _FontSizeButton(
                        icon: CupertinoIcons.minus,
                        label: 'Уменьшить',
                        onPressed: notifier.canDecrease
                            ? () => notifier.decreaseFontSize()
                            : null,
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _FontSizeButton(
                        icon: CupertinoIcons.plus,
                        label: 'Увеличить',
                        onPressed: notifier.canIncrease
                            ? () => notifier.increaseFontSize()
                            : null,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Preview text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Пример текста',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: currentSize,
                          height: 1.6,
                        ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Current size display
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.gradientPurple,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${currentSize.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'pt',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Decrease button
            Row(
              children: [
                Expanded(
                  child: _FontSizeButton(
                    icon: Icons.remove,
                    label: 'Уменьшить',
                    onPressed: notifier.canDecrease
                        ? () => notifier.decreaseFontSize()
                        : null,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FontSizeButton(
                    icon: Icons.add,
                    label: 'Увеличить',
                    onPressed: notifier.canIncrease
                        ? () => notifier.increaseFontSize()
                        : null,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Preview text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Пример текста',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: currentSize,
                      height: 1.6,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (PlatformUtils.useCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        child: const Icon(CupertinoIcons.textformat_size),
        onPressed: () => _showFontSizeBottomSheet(context, ref),
      );
    }
    return IconButton(
      icon: const Icon(Icons.text_fields),
      tooltip: 'Размер шрифта',
      onPressed: () => _showFontSizeBottomSheet(context, ref),
    );
  }
}

class _FontSizeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _FontSizeButton({
    required this.icon,
    required this.label,
    this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isPrimary
        ? AppTheme.gradientPurple
        : [
            AppTheme.textSecondary.withValues(alpha: 0.1),
            AppTheme.textSecondary.withValues(alpha: 0.15),
          ];

    if (PlatformUtils.useCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : AppTheme.textSecondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : AppTheme.textPrimary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : AppTheme.textSecondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : AppTheme.textPrimary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
