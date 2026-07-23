import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

class StorageService {
  static const String keyWrongQuestions = 'wrong_questions_list';
  static const String keyHighScore = 'high_score';
  static const String keyStreak = 'daily_streak';
  static const String keyLastPlayDate = 'last_play_date';
  static const String keyCategoryLevelPrefix = 'cat_level_';
  static const String keyCategoryScorePrefix = 'cat_score_';
  static const String keyCategoryUnlockedPrefix = 'cat_unlocked_';
  static const String keyAskedQuestionsPrefix = 'asked_questions_';
  static const String keyDailyTaskPrefix = 'daily_task_';
  static const String keyDailyTasksResetDate = 'daily_tasks_reset_date';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // High Score
  int getHighScore() {
    return _prefs.getInt(keyHighScore) ?? 0;
  }

  Future<void> saveHighScore(int score) async {
    final currentHigh = getHighScore();
    if (score > currentHigh) {
      await _prefs.setInt(keyHighScore, score);
    }
  }

  // Daily Streak
  int getStreak() {
    return _prefs.getInt(keyStreak) ?? 0;
  }

  String? getLastPlayDate() {
    return _prefs.getString(keyLastPlayDate);
  }

  Future<void> updateStreak() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastPlayStr = getLastPlayDate();
    int currentStreak = getStreak();

    if (lastPlayStr == null) {
      // First time playing
      currentStreak = 1;
    } else {
      final lastPlayDate = DateTime.parse(lastPlayStr);
      final todayDate = DateTime.parse(todayStr);
      final difference = todayDate.difference(lastPlayDate).inDays;

      if (difference == 1) {
        // Played yesterday, increment streak
        currentStreak += 1;
      } else if (difference > 1) {
        // Missed days, reset streak
        currentStreak = 1;
      }
      // If difference is 0 (already played today), do nothing
    }

    await _prefs.setInt(keyStreak, currentStreak);
    await _prefs.setString(keyLastPlayDate, todayStr);
  }

  // Category Level
  int getCategoryLevel(String categoryId) {
    // Quran is unlocked and starts at 1, others start at 1 but might be locked
    return _prefs.getInt('$keyCategoryLevelPrefix$categoryId') ?? 1;
  }

  Future<void> setCategoryLevel(String categoryId, int level) async {
    await _prefs.setInt('$keyCategoryLevelPrefix$categoryId', level);
  }

  // Category Score
  int getCategoryScore(String categoryId) {
    return _prefs.getInt('$keyCategoryScorePrefix$categoryId') ?? 0;
  }

  Future<void> addCategoryScore(String categoryId, int addedPoints) async {
    final currentScore = getCategoryScore(categoryId);
    await _prefs.setInt('$keyCategoryScorePrefix$categoryId', currentScore + addedPoints);
  }

  // Category Unlocked Status
  bool isCategoryUnlocked(String categoryId) {
    if (categoryId == 'quran') return true; // Quran always unlocked
    if (categoryId == 'history') return true; // History always unlocked
    if (categoryId == 'enc_caliphs') return true; // First encyclopedia category always unlocked
    return _prefs.getBool('$keyCategoryUnlockedPrefix$categoryId') ?? false;
  }

  Future<void> unlockCategory(String categoryId) async {
    await _prefs.setBool('$keyCategoryUnlockedPrefix$categoryId', true);
  }

  // Reset Progress
  Future<void> resetAllProgress() async {
    await _prefs.clear();
  }

  // Wrong Questions Persistence
  List<Question> getWrongQuestions() {
    final List<String> list = _prefs.getStringList(keyWrongQuestions) ?? [];
    return list.map((jsonStr) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        return Question.fromJson(decoded);
      } catch (e) {
        return null;
      }
    }).whereType<Question>().toList();
  }

  Future<void> saveWrongQuestion(Question question) async {
    final List<Question> currentList = getWrongQuestions();
    // Avoid duplicates
    if (currentList.any((q) => q.id == question.id)) return;
    
    currentList.add(question);
    final List<String> serialized = currentList.map((q) => json.encode(q.toJson())).toList();
    await _prefs.setStringList(keyWrongQuestions, serialized);
  }

  Future<void> removeWrongQuestion(String id) async {
    final List<Question> currentList = getWrongQuestions();
    currentList.removeWhere((q) => q.id == id);
    final List<String> serialized = currentList.map((q) => json.encode(q.toJson())).toList();
    await _prefs.setStringList(keyWrongQuestions, serialized);
  }

  Future<void> clearWrongQuestions() async {
    await _prefs.remove(keyWrongQuestions);
  }

  // Asked Questions Persistence (to prevent repeating)
  List<String> getAskedQuestions(String categoryId) {
    return _prefs.getStringList('$keyAskedQuestionsPrefix$categoryId') ?? [];
  }

  Future<void> markQuestionAsAsked(String categoryId, String questionId) async {
    final List<String> asked = getAskedQuestions(categoryId);
    if (!asked.contains(questionId)) {
      asked.add(questionId);
      await _prefs.setStringList('$keyAskedQuestionsPrefix$categoryId', asked);
    }
  }

  Future<void> clearAskedQuestions(String categoryId) async {
    await _prefs.remove('$keyAskedQuestionsPrefix$categoryId');
  }

  // Daily Tasks Checklist
  bool isDailyTaskCompleted(String taskId) {
    return _prefs.getBool('$keyDailyTaskPrefix$taskId') ?? false;
  }

  Future<void> setDailyTaskCompleted(String taskId, bool completed) async {
    await _prefs.setBool('$keyDailyTaskPrefix$taskId', completed);
  }

  String? getDailyTasksResetDate() {
    return _prefs.getString(keyDailyTasksResetDate);
  }

  Future<void> saveDailyTasksResetDate(String dateStr) async {
    await _prefs.setString(keyDailyTasksResetDate, dateStr);
  }

  Future<void> checkAndResetDailyTasks() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastResetStr = getDailyTasksResetDate();

    if (lastResetStr != todayStr) {
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(keyDailyTaskPrefix)) {
          await _prefs.remove(key);
        }
      }
      await saveDailyTasksResetDate(todayStr);
    }
  }
}
