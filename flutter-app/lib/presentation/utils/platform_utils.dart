import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Утилиты для определения платформы
class PlatformUtils {
  /// Проверяет, является ли текущая платформа iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Проверяет, является ли текущая платформа Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Возвращает true, если нужно использовать Cupertino стиль
  static bool get useCupertino => isIOS;
}

/// Платформо-зависимый виджет для отображения индикатора загрузки
class PlatformProgressIndicator extends StatelessWidget {
  final Color? color;
  final double? value;

  const PlatformProgressIndicator({
    super.key,
    this.color,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.useCupertino) {
      return CupertinoActivityIndicator();
    }
    return CircularProgressIndicator(
      valueColor: color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
      value: value,
    );
  }
}

