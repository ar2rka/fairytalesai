import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Color? backgroundColor;

  const WhiteCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadiusValue = borderRadius ?? 24.0;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        child: cardContent,
      );
    }

    if (margin != null) {
      return Container(
        margin: margin,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
