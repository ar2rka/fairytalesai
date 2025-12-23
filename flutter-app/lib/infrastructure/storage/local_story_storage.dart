import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/story.dart';

class LocalStoryStorage {
  static const String _boxName = 'stories';
  static Box<String>? _box;

  /// Инициализация хранилища
  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Сохранить список историй для пользователя
  Future<void> saveStories(String userId, List<Story> stories) async {
    if (_box == null) await init();
    
    final storiesJson = stories.map((s) => s.toJson()).toList();
    await _box!.put('stories_$userId', jsonEncode(storiesJson));
    await _box!.put('stories_${userId}_timestamp', DateTime.now().toIso8601String());
  }

  /// Получить список историй для пользователя
  Future<List<Story>> getStories(String userId) async {
    if (_box == null) await init();
    
    final storiesJsonString = _box!.get('stories_$userId');
    if (storiesJsonString == null) return [];
    
    try {
      final storiesJson = jsonDecode(storiesJsonString) as List;
      return storiesJson
          .map((json) => Story.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Сохранить одну историю
  Future<void> saveStory(String userId, Story story) async {
    if (_box == null) await init();
    
    final stories = await getStories(userId);
    final existingIndex = stories.indexWhere((s) => s.id == story.id);
    
    if (existingIndex >= 0) {
      stories[existingIndex] = story;
    } else {
      stories.add(story);
    }
    
    await saveStories(userId, stories);
  }

  /// Получить историю по ID
  Future<Story?> getStoryById(String userId, String storyId) async {
    final stories = await getStories(userId);
    try {
      return stories.firstWhere((s) => s.id == storyId);
    } catch (e) {
      return null;
    }
  }

  /// Удалить историю
  Future<void> deleteStory(String userId, String storyId) async {
    final stories = await getStories(userId);
    stories.removeWhere((s) => s.id == storyId);
    await saveStories(userId, stories);
  }

  /// Очистить все истории для пользователя
  Future<void> clearStories(String userId) async {
    if (_box == null) await init();
    await _box!.delete('stories_$userId');
    await _box!.delete('stories_${userId}_timestamp');
  }

  /// Получить время последнего обновления
  DateTime? getLastUpdateTime(String userId) {
    if (_box == null) return null;
    
    final timestamp = _box!.get('stories_${userId}_timestamp');
    if (timestamp == null) return null;
    
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
}

