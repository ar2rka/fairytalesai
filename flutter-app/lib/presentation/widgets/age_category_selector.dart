import 'package:flutter/material.dart';
import '../../domain/value_objects/age_category.dart';
import '../theme/app_theme.dart';

class AgeCategorySelector extends StatefulWidget {
  final AgeCategory? selectedCategory;
  final ValueChanged<AgeCategory> onCategorySelected;

  const AgeCategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<AgeCategorySelector> createState() => _AgeCategorySelectorState();
}

class _AgeCategorySelectorState extends State<AgeCategorySelector>
    with SingleTickerProviderStateMixin {
  late AgeCategory? _selectedCategory;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AgeCategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _selectedCategory = widget.selectedCategory;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectCategory(AgeCategory category) {
    setState(() {
      _selectedCategory = category;
    });
    _controller.forward(from: 0.0).then((_) {
      _controller.reverse();
    });
    widget.onCategorySelected(category);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategoryCard(
          category: AgeCategory.twoToThree,
          icon: Icons.baby_changing_station,
          gradient: AppTheme.gradientPink,
        ),
        const SizedBox(height: 12),
        _buildCategoryCard(
          category: AgeCategory.threeToFive,
          icon: Icons.child_care,
          gradient: AppTheme.gradientBlue,
        ),
        const SizedBox(height: 12),
        _buildCategoryCard(
          category: AgeCategory.fiveToSeven,
          icon: Icons.school,
          gradient: AppTheme.gradientPurple,
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required AgeCategory category,
    required IconData icon,
    required List<Color> gradient,
  }) {
    final isSelected = _selectedCategory == category;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _selectCategory(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? gradient
                    : [
                        Colors.white,
                        Colors.white,
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : gradient.first.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : gradient.first.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : gradient.first,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayLabel,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (category == AgeCategory.twoToThree) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Малыши и ясельки',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppTheme.textSecondary,
                                  ),
                        ),
                      ] else if (category == AgeCategory.threeToFive) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Дошкольники',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppTheme.textSecondary,
                                  ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'Школьники',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppTheme.primaryPurple,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
