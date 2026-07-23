import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../services/quran_api_service.dart';
import '../services/hadith_api_service.dart';
import '../services/remote_quiz_service.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

class QuizProvider with ChangeNotifier {
  final StorageService _storageService;
  late final QuranApiService _quranApiService;
  late final HadithApiService _hadithApiService;
  late final RemoteQuizService _remoteQuizService;

  QuizProvider(this._storageService) {
    _quranApiService = QuranApiService(_storageService);
    _hadithApiService = HadithApiService(_storageService);
    _remoteQuizService = RemoteQuizService(_storageService);
  }

  // Categories list
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  // Active Category & Level
  Category? _activeCategory;
  Category? get activeCategory => _activeCategory;
  int _activeLevel = 1;
  int get activeLevel => _activeLevel;

  // Quiz Play State
  List<Question> _questions = [];
  List<Question> get questions => _questions;
  
  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;

  bool _isAnswered = false;
  bool get isAnswered => _isAnswered;

  int? _selectedAnswerIndex;
  int? get selectedAnswerIndex => _selectedAnswerIndex;

  int _score = 0;
  int get score => _score;

  int _correctAnswersCount = 0;
  int get correctAnswersCount => _correctAnswersCount;

  // Bento Stats
  int get totalPoints => _categories.fold(0, (sum, cat) => sum + cat.score);
  int get streakCount => _storageService.getStreak();
  int get highScore => _storageService.getHighScore();

  // Timer settings
  int _totalTimeForQuestion = 30;
  int get totalTimeForQuestion => _totalTimeForQuestion;
  int _timeLeft = 30;
  int get timeLeft => _timeLeft;
  Timer? _timer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isReviewMode = false;
  bool get isReviewMode => _isReviewMode;

  int get wrongQuestionsCount => _storageService.getWrongQuestions().length;

  List<Question> getWrongQuestionsList() {
    return _storageService.getWrongQuestions();
  }

  void removeWrongQuestion(String id) {
    _storageService.removeWrongQuestion(id);
    notifyListeners();
  }

  /// Load all categories and sync their status from SharedPreferences
  void loadCategories() {
    final list = Category.defaultCategories;
    _categories = list.map((cat) {
      final currentLevel = _storageService.getCategoryLevel(cat.id);
      final isUnlocked = _storageService.isCategoryUnlocked(cat.id);
      final score = _storageService.getCategoryScore(cat.id);
      return cat.copyWith(
        currentLevel: currentLevel,
        isLocked: !isUnlocked,
        score: score,
      );
    }).toList();
    notifyListeners();
  }

  /// Daily Tasks Management
  Future<void> initDailyTasks() async {
    await _storageService.checkAndResetDailyTasks();
    notifyListeners();
  }

  bool isDailyTaskCompleted(String taskId) {
    return _storageService.isDailyTaskCompleted(taskId);
  }

  Future<void> toggleDailyTask(String taskId, int pointsAwarded) async {
    final currentlyCompleted = _storageService.isDailyTaskCompleted(taskId);
    final nextState = !currentlyCompleted;
    
    await _storageService.setDailyTaskCompleted(taskId, nextState);
    
    if (nextState) {
      await _storageService.addCategoryScore('quran', pointsAwarded);
    } else {
      await _storageService.addCategoryScore('quran', -pointsAwarded);
    }

    loadCategories();

    final user = FirebaseService().currentUser;
    if (user != null) {
      FirebaseService().syncLocalStats(
        points: totalPoints,
        streak: streakCount,
      );
    }
    
    notifyListeners();
  }

  /// Reset state synchronously to prevent old state from flashing when opening a new quiz
  void resetQuizStateSync() {
    _questions = [];
    _currentQuestionIndex = 0;
    _isAnswered = false;
    _selectedAnswerIndex = null;
    _score = 0;
    _correctAnswersCount = 0;
    _isLoading = true;
    _totalTimeForQuestion = 30;
    _timeLeft = 30;
    _isReviewMode = false;
    _timer?.cancel();
  }

  /// Initialize quiz for a selected category and level
  Future<void> startQuiz(Category category, int level) async {
    _activeCategory = category;
    _activeLevel = level;
    _questions = [];
    _currentQuestionIndex = 0;
    _isAnswered = false;
    _selectedAnswerIndex = null;
    _score = 0;
    _correctAnswersCount = 0;
    _isLoading = true;
    _totalTimeForQuestion = 30;
    _timeLeft = 30;
    _isReviewMode = false;
    notifyListeners();

    try {
      if (category.id == 'quran') {
        // Quran sciences fetches dynamic question from API
        final q = await _quranApiService.fetchDynamicQuranQuestion(level);
        _questions = [q];
      } else if (category.id == 'hadith') {
        // Hadith fetches dynamic question from Hadith API
        final q = await _hadithApiService.fetchDynamicHadithQuestion(level);
        _questions = [q];
      } else {
        // Fiqh, Aqeedah, Seerah fetch from remote JSON / local fallback
        _questions = await _remoteQuizService.fetchQuestions(category.id, level);
        if (_questions.isEmpty) {
          throw Exception('No questions loaded');
        }
      }
    } catch (e) {
      // Fallback to local fallback database JSON instead of ultimate fallback
      _questions = await _remoteQuizService.fetchLocalFallbackQuestions(category.id, level);
      if (_questions.isEmpty) {
        _questions = _remoteQuizService.getUltimateFallbackQuestions(category.id, level);
      }
    } finally {
      // Shuffle options for all loaded questions to randomize choice positions
      _questions = _questions.map((q) => q.shuffleOptions()).toList();

      _isLoading = false;
      notifyListeners();
      if (_questions.isNotEmpty) {
        _startTimer();
      }
    }
  }

  /// Initialize quiz using incorrect questions only (Review Mode)
  void startReviewQuiz() {
    _activeCategory = null;
    _activeLevel = 1;
    _isReviewMode = true;
    _questions = _storageService.getWrongQuestions().map((q) => q.shuffleOptions()).toList();
    _currentQuestionIndex = 0;
    _isAnswered = false;
    _selectedAnswerIndex = null;
    _score = 0;
    _correctAnswersCount = 0;
    _isLoading = false;
    _totalTimeForQuestion = 30;
    _timeLeft = 30;
    notifyListeners();

    if (_questions.isNotEmpty) {
      _startTimer();
    }
  }

  /// Timer control
  void _startTimer() {
    _timer?.cancel();
    
    // Calculate dynamic time for the current question
    final currentQuestion = _questions[_currentQuestionIndex];
    int questionDuration = 30; // Base: 30 seconds

    if (currentQuestion.verseOrHadithText != null && currentQuestion.verseOrHadithText!.length > 40) {
      questionDuration = 45; // Give 45 seconds if there's a long Quranic verse or Hadith to read!
    } else if (currentQuestion.question.length > 65) {
      questionDuration = 40; // Give 40 seconds if the question itself is very long
    }

    _totalTimeForQuestion = questionDuration;
    _timeLeft = questionDuration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        _timer?.cancel();
        // Time ran out, count as incorrect selection
        selectAnswer(-1);
      }
    });
  }

  /// Select an option
  void selectAnswer(int optionIndex) {
    if (_isAnswered) return;
    _timer?.cancel();
    _isAnswered = true;
    _selectedAnswerIndex = optionIndex;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = optionIndex == currentQuestion.correctAnswerIndex;

    if (isCorrect) {
      _correctAnswersCount++;
      
      // If we are in review mode, answer correctness removes the question from the mistakes list
      if (_isReviewMode) {
        _storageService.removeWrongQuestion(currentQuestion.id);
      }

      // Score calculation: 3 base points + speed bonus (up to 3 extra points)
      final pointsGained = 3 + (_timeLeft / 10).floor();
      _score += pointsGained;
      HapticFeedback.lightImpact(); // Success haptic
    } else {
      // If answered incorrectly, save it to our mistakes log
      _storageService.saveWrongQuestion(currentQuestion);
      HapticFeedback.heavyImpact(); // Failure haptic
    }

    notifyListeners();
  }

  /// Move to next question or complete stage
  bool nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _isAnswered = false;
      _selectedAnswerIndex = null;
      _startTimer();
      notifyListeners();
      return true; // Has next
    } else {
      _completeStage();
      return false; // Completed
    }
  }

  /// Handle stage completion
  void _completeStage() async {
    // If review mode, we just update streak and save high score, but skip category unlocking
    if (_isReviewMode) {
      await _storageService.updateStreak();
      final newTotalPoints = totalPoints + _score;
      await _storageService.saveHighScore(newTotalPoints);
      notifyListeners();
      return;
    }

    if (_activeCategory == null) return;
    
    // Save streak
    await _storageService.updateStreak();

    // Save score
    await _storageService.addCategoryScore(_activeCategory!.id, _score);

    // Save high score
    final newTotalPoints = totalPoints + _score;
    await _storageService.saveHighScore(newTotalPoints);

    // If score is decent (e.g. at least one correct answer), unlock next level or category
    if (_correctAnswersCount > 0) {
      // Set level + 1
      final nextLevel = _activeLevel + 1;
      await _storageService.setCategoryLevel(_activeCategory!.id, nextLevel);

      // Category unlock progression:
      // Quran level 2 unlocks Aqeedah.
      // Aqeedah level 2 unlocks Fiqh.
      // Fiqh level 2 unlocks Hadith.
      // Hadith level 2 unlocks Seerah.
      if (_activeCategory!.id == 'quran' && nextLevel >= 2) {
        await _storageService.unlockCategory('aqeedah');
      } else if (_activeCategory!.id == 'aqeedah' && nextLevel >= 2) {
        await _storageService.unlockCategory('fiqh');
      } else if (_activeCategory!.id == 'fiqh' && nextLevel >= 2) {
        await _storageService.unlockCategory('hadith');
      } else if (_activeCategory!.id == 'hadith' && nextLevel >= 2) {
        await _storageService.unlockCategory('seerah');
      } else if (_activeCategory!.id == 'seerah' && nextLevel >= 2) {
        await _storageService.unlockCategory('history');
      } else if (_activeCategory!.id == 'enc_caliphs' && nextLevel >= 11) {
        await _storageService.unlockCategory('enc_dynasties');
      } else if (_activeCategory!.id == 'enc_dynasties' && nextLevel >= 11) {
        await _storageService.unlockCategory('enc_battles');
      } else if (_activeCategory!.id == 'enc_battles' && nextLevel >= 11) {
        await _storageService.unlockCategory('enc_scholars');
      } else if (_activeCategory!.id == 'enc_scholars' && nextLevel >= 11) {
        await _storageService.unlockCategory('enc_companions');
      }
    }

    // Refresh categories status from storage
    loadCategories();

    // Sync to Firestore if logged in
    try {
      final firebaseService = FirebaseService();
      if (firebaseService.currentUser != null) {
        await firebaseService.syncLocalStats(
          points: totalPoints,
          streak: _storageService.getStreak(),
        );
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
