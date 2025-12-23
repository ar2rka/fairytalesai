import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final storyFontSizeProvider = StateNotifierProvider<StoryFontSizeNotifier, double>(
  (ref) => StoryFontSizeNotifier(),
);

class StoryFontSizeNotifier extends StateNotifier<double> {
  static const String _fontSizeKey = 'story_font_size';
  static const double _defaultFontSize = 16.0;
  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 24.0;
  static const double _fontSizeStep = 2.0;

  StoryFontSizeNotifier() : super(_defaultFontSize) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(_fontSizeKey);
    if (fontSize != null && fontSize >= _minFontSize && fontSize <= _maxFontSize) {
      state = fontSize;
    }
  }

  Future<void> _saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
  }

  Future<void> increaseFontSize() async {
    if (state < _maxFontSize) {
      final newSize = (state + _fontSizeStep).clamp(_minFontSize, _maxFontSize);
      state = newSize;
      await _saveFontSize(newSize);
    }
  }

  Future<void> decreaseFontSize() async {
    if (state > _minFontSize) {
      final newSize = (state - _fontSizeStep).clamp(_minFontSize, _maxFontSize);
      state = newSize;
      await _saveFontSize(newSize);
    }
  }

  Future<void> resetFontSize() async {
    state = _defaultFontSize;
    await _saveFontSize(_defaultFontSize);
  }

  bool get canIncrease => state < _maxFontSize;
  bool get canDecrease => state > _minFontSize;
}

