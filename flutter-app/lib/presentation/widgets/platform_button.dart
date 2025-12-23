import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/platform_utils.dart';
import '../theme/app_theme.dart';

/// Платформо-зависимая кнопка
/// На iOS использует CupertinoButton, на Android - Material Button
class PlatformButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final bool filled;

  const PlatformButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.useCupertino) {
      if (filled) {
        return CupertinoButton.filled(
          onPressed: onPressed,
          color: color ?? AppTheme.primaryPurple,
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      return CupertinoButton(
        onPressed: onPressed,
        color: color,
        child: Text(
          text,
          style: TextStyle(
            color: textColor ?? (color ?? AppTheme.primaryPurple),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppTheme.primaryPurple,
          foregroundColor: textColor ?? Colors.white,
        ),
        child: Text(text),
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppTheme.primaryPurple,
      ),
      child: Text(text),
    );
  }
}

