import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/question.dart';
import 'storage_service.dart';

class RemoteQuizService {
  // Base URL for HadeethEnc API (Encyclopedia of Translated Prophetic Hadiths)
  static const String hadeethEncBaseUrl = 'https://hadeethenc.com/api/v1';

  final StorageService _storageService;

  RemoteQuizService(this._storageService);

  /// Maps local categories to HadeethEnc category IDs
  int _mapCategoryToHadeethId(String categoryId) {
    switch (categoryId) {
      case 'aqeedah':
        return 3; // HadeethEnc Category 3 is "العقيدة"
      case 'fiqh':
        return 4; // HadeethEnc Category 4 is "الفقه وأصوله"
      case 'seerah':
        return 7; // HadeethEnc Category 7 is "السيرة والتاريخ"
      default:
        return 5; // Fallback to "الفضائل والآداب"
    }
  }

  List<String> _getDistractorAnswersForCategory(String categoryId) {
    switch (categoryId) {
      case 'aqeedah':
        return [
          'الدعوة إلى التفكر في عظمة خلق الله لزيادة اليقين والإيمان.',
          'أهمية الإخلاص لله تعالى وتجنب الرياء في القول والعمل والنية.',
          'بيان أثر المعاصي والذنوب على إيمان الفرد واستقراره النفسي.',
          'الرضا الكامل بقضاء الله وقدره خيره وشره في جميع الأحوال.',
          'أهمية تعظيم شعائر الله في القلوب والابتعاد عن المحرمات.',
          'بيان شروط قبول الأعمال الصالحة والإخلاص والمتابعة للنبي.',
          'وجوب الاستعانة بالله وحده وتفويض كل الأمور لرب العالمين.',
          'أثر توحيد الله في إرساء الطمأنينة والأمان النفسي للمؤمن.'
        ];
      case 'fiqh':
        return [
          'بيان شروط صحة العبادات والفرائض اليومية بالتفصيل الشرعي.',
          'الحرص على أداء العبادات والصلوات جماعة في المسجد لنيل الأجر.',
          'أهمية التفقه في الدين ومعرفة الحلال والحرام في المعاملات المالية.',
          'توضيح الرخص الشرعية التي يسرها الإسلام للمسافر والمريض.',
          'بيان فضل الطهارة والوضوء وأثرها في غفران الذنوب والخطايا.',
          'المحافظة على النوافل والسنن الرواتب للتقرب أكثر إلى الله.',
          'وجوب أداء الحقوق والواجبات المالية والشرعية لأصحابها دون تأخير.',
          'أهمية النية وتحديدها قبل الشروع في العبادات الواجبة.'
        ];
      case 'seerah':
      default:
        return [
          'وجوب الصبر والثبات عند ملاقاة الشدائد والابتلاءات في سبيل الله.',
          'أهمية المشورة وأخذ بآراء أصحاب الخبرة في شؤون المجتمع والبلاد.',
          'أهمية إخلاص النية لله تعالى وتصفية القلب من الأحقاد والضغائن.',
          'أثر التربية الصالحة والقدوة الحسنة في نشأة الجيل المسلم.',
          'فضل صلة الأرحام وحسن الجوار والإحسان إلى الأقارب والفقراء.',
          'ضرورة التخطيط الجيد والاتخاذ بالأسباب مع التوكل التام على الله.',
          'بيان أهمية حفظ اللسان وتجنب نقل الكلام الذي يثير الفتن.',
          'التحلي بالرفق واللين في دعوة الناس إلى طريق الحق والخير.'
        ];
    }
  }

  /// Fetches questions online dynamically from HadeethEnc API.
  /// Falls back to local asset JSON database if offline.
  Future<List<Question>> fetchQuestions(String categoryId, int level) async {
    if (categoryId == 'history' || categoryId.startsWith('enc_')) {
      return await fetchLocalFallbackQuestions(categoryId, level);
    }
    try {
      final int encCategoryId = _mapCategoryToHadeethId(categoryId);
      
      int maxPage = 5;
      if (categoryId == 'aqeedah') maxPage = 7;
      if (categoryId == 'fiqh') maxPage = 15;
      if (categoryId == 'seerah') maxPage = 3;

      final random = Random();
      final int page = random.nextInt(maxPage) + 1;
      
      // Step 1: Fetch list of Hadiths for this category from a random page
      final listResponse = await http.get(
        Uri.parse('$hadeethEncBaseUrl/hadeeths/list/?language=ar&category_id=$encCategoryId&per_page=30&page=$page'),
      ).timeout(const Duration(seconds: 5));

      if (listResponse.statusCode == 200) {
        final Map<String, dynamic> decodedList = json.decode(listResponse.body);
        if (decodedList['data'] is List && (decodedList['data'] as List).isNotEmpty) {
          final List<dynamic> data = decodedList['data'];
          
          final askedList = _storageService.getAskedQuestions(categoryId);

          // Filter out recently asked Hadiths
          List<dynamic> availableHadiths = data
              .where((item) => !askedList.contains('online_${categoryId}_${item['id']}'))
              .toList();

          if (availableHadiths.isEmpty) {
            await _storageService.clearAskedQuestions(categoryId);
            availableHadiths = data;
          }

          final randomItem = availableHadiths[random.nextInt(availableHadiths.length)];
          final String hadithId = randomItem['id'].toString();

          // Step 2: Fetch details for this specific Hadith
          final detailResponse = await http.get(
            Uri.parse('$hadeethEncBaseUrl/hadeeths/one/?id=$hadithId&language=ar'),
          ).timeout(const Duration(seconds: 5));

          if (detailResponse.statusCode == 200) {
            final Map<String, dynamic> detail = json.decode(detailResponse.body);
            
            final String hadithText = detail['hadeeth'] ?? '';
            final String hadithTitle = detail['title'] ?? '';
            final String rawExplanation = detail['explanation'] ?? '';
            final String reference = detail['reference'] ?? 'موسوعة الأحاديث النبوية';
            final List<dynamic> hints = detail['hints'] ?? [];

            // The correct answer is the first hint/takeaway of the Hadith
            String correctOption = 'الحث على تقوى الله والعمل بموجب هذا الحديث الشريف';
            if (hints.isNotEmpty && hints[0].toString().trim().isNotEmpty) {
              correctOption = hints[0].toString().trim();
            } else if (hadithTitle.isNotEmpty) {
              correctOption = hadithTitle;
            }

            // Distractor options (Conceptually close and educational moral lessons)
            final distractorPool = _getDistractorAnswersForCategory(categoryId);
            final shuffledPool = distractorPool.where((ans) => ans != correctOption).toList()..shuffle(random);

            final List<String> distractors = [];
            if (shuffledPool.length >= 2) {
              distractors.addAll(shuffledPool.take(2));
            } else {
              // Fallback to defaults
              if (categoryId == 'fiqh') {
                distractors.addAll([
                  'بيان شروط صحة العبادات والفرائض اليومية بالتفصيل الشرعي',
                  'الحرص على أداء العبادات جماعة في المسجد لنيل الأجر'
                ]);
              } else if (categoryId == 'aqeedah') {
                distractors.addAll([
                  'الدعوة إلى التفكر في مخلوقات الله لزيادة اليقين والخشوع',
                  'بيان أثر المعاصي على إيمان الفرد والمجتمع'
                ]);
              } else {
                distractors.addAll([
                  'بيان شروط صحة العبادات والفرائض اليومية بالتفصيل الشرعي',
                  'الدعوة إلى الصبر واليقين عند الابتلاء والرضا بقضاء الله'
                ]);
              }
            }

            final List<String> options = [correctOption, ...distractors]..shuffle(random);
            final int correctIndex = options.indexOf(correctOption);

            final Question question = Question(
              id: 'online_${categoryId}_$hadithId',
              category: categoryId,
              question: 'ما هو التوجيه أو الفائدة الأساسية المستفادة من هذا الحديث النبوي؟',
              options: options,
              correctAnswerIndex: correctIndex,
              explanation: '$rawExplanation\n\n(المصدر: $reference)',
              verseOrHadithText: hadithText,
            );

            await _storageService.markQuestionAsAsked(categoryId, question.id);
            return [question];
          }
        }
      }
      throw Exception('Failed to load online Hadith list');
    } catch (e) {
      // Fallback to local asset JSON when offline
      return await fetchLocalFallbackQuestions(categoryId, level);
    }
  }

  /// Loads from the local verified asset questions database
  Future<List<Question>> fetchLocalFallbackQuestions(String categoryId, int level) async {
    try {
      final isEncyclopedia = categoryId.startsWith('enc_');
      final assetPath = isEncyclopedia
          ? 'assets/data/encyclopedia_questions.json'
          : 'assets/data/questions_fallback.json';
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      if (data['questions'] is List) {
        final List<dynamic> allQuestions = data['questions'];
        final List<Question> filtered = allQuestions
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .where((q) => q.category == categoryId)
            .toList();

        return _getQuestionsForLevel(filtered, categoryId, level);
      }
    } catch (e) {
      return getUltimateFallbackQuestions(categoryId, level);
    }
    return [];
  }

  List<Question> _getQuestionsForLevel(List<Question> list, String categoryId, int level) {
    if (list.isEmpty) return [];

    List<Question> pool = list;
    final isEncyclopedia = categoryId.startsWith('enc_');

    if (categoryId == 'history') {
      final List<String> levelIds = [];
      if (level == 1) {
        levelIds.addAll(['history_1', 'history_2', 'history_3', 'history_4']);
      } else if (level == 2) {
        levelIds.addAll(['history_5', 'history_6', 'history_7', 'history_8']);
      } else if (level == 3) {
        levelIds.addAll(['history_9', 'history_10', 'history_11', 'history_12']);
      } else if (level == 4) {
        levelIds.addAll(['history_13', 'history_14', 'history_15', 'history_16']);
      } else {
        levelIds.addAll(['history_17', 'history_18', 'history_19', 'history_20']);
      }
      pool = list.where((q) => levelIds.contains(q.id)).toList();
    } else if (isEncyclopedia) {
      final int startIndex = (level - 1) * 20;
      final List<String> levelIds = [];
      for (int i = 1; i <= 20; i++) {
        final int qNum = startIndex + i;
        levelIds.add('${categoryId}_$qNum');
      }
      pool = list.where((q) => levelIds.contains(q.id)).toList();
      if (pool.isEmpty) {
        pool = list; // fallback to all questions if level exceeds database size
      }
    }

    final askedList = _storageService.getAskedQuestions(categoryId);

    // Filter out recently asked local questions
    List<Question> available = pool
        .where((q) => !askedList.contains(q.id))
        .toList();

    // If we run out of questions, reset history for this category
    final int minAvailable = isEncyclopedia ? 10 : 2;
    if (available.length < minAvailable) {
      _storageService.clearAskedQuestions(categoryId);
      available = pool;
    }

    final random = Random();
    final List<Question> shuffledList = List<Question>.from(available)..shuffle(random);

    final int questionsPerLevel = isEncyclopedia ? 10 : 2;
    final List<Question> selected = shuffledList.take(questionsPerLevel).toList();

    // Add selected IDs to history
    for (var q in selected) {
      _storageService.markQuestionAsAsked(categoryId, q.id);
    }

    return selected;
  }

  List<Question> getUltimateFallbackQuestions(String categoryId, int level) {
    if (categoryId == 'aqeedah') {
      return [
        Question(
          id: 'ult_aqeedah_1',
          category: 'aqeedah',
          question: 'ما هو معنى التوحيد؟',
          options: [
            'إفراد الله تعالى بالعبادة والربوبية والأسماء والصفات',
            'الاعتقاد بوجود صانع للكون مع إشراك غيره معه في العبادة',
            'التأمل في الطبيعة دون الحاجة إلى الشرائع والرسل'
          ],
          correctAnswerIndex: 0,
          explanation: 'التوحيد هو أساس الإسلام وهو إفراد الله عز وجل بكل ما يختص به من الربوبية والألوهية والأسماء والصفات.',
          verseOrHadithText: 'قال تعالى: «قُلْ هُوَ اللَّهُ أَحَدٌ»',
        )
      ];
    } else if (categoryId == 'fiqh') {
      return [
        Question(
          id: 'ult_fiqh_1',
          category: 'fiqh',
          question: 'ما هي شروط الصلاة الأساسية؟',
          options: [
            'الطهارة ودخول الوقت واستقبال القبلة وستر العورة',
            'قراءة سورة الملك قبل الركوع دائماً',
            'صلاة ركعتين نافلة بعد كل فريضة مباشرة'
          ],
          correctAnswerIndex: 0,
          explanation: 'شروط صحة الصلاة هي الأمور التي تسبق الصلاة ويجب استمرارها فيها مثل: الإسلام، العقل، التمييز، رفع الحدث، إزالة النجاسة، ستر العورة، استقبال القبلة، ودخول الوقت.',
          verseOrHadithText: 'قال تعالى: «إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا»',
        )
      ];
    } else if (categoryId == 'history') {
      return [
        Question(
          id: 'ult_history_1',
          category: 'history',
          question: 'من هو أول الخلفاء الراشدين؟',
          options: [
            'أبو بكر الصديق رضي الله عنه',
            'عمر بن الخطاب رضي الله عنه',
            'عثمان بن عفان رضي الله عنه'
          ],
          correctAnswerIndex: 0,
          explanation: 'أبو بكر الصديق رضي الله عنه هو أول الخلفاء الراشدين وتولى الخلافة بعد وفاة النبي صلى الله عليه وسلم.',
          verseOrHadithText: '«تاريخ الخلفاء للسيوطي»',
        )
      ];
    } else {
      return [
        Question(
          id: 'ult_default_1',
          category: categoryId,
          question: 'ما هو أهم أركان الإسلام العملية بعد الشهادتين؟',
          options: ['إقام الصلاة', 'إيتاء الزكاة', 'صوم رمضان'],
          correctAnswerIndex: 0,
          explanation: 'الصلاة هي عمود الدين والركن الثاني من أركان الإسلام العملية كما في حديث بني الإسلام على خمس.',
          verseOrHadithText: 'حديث: «بُنِيَ الإِسْلاَمُ عَلَى خَمْسٍ... وَإِقَامِ الصَّلاَةِ»',
        )
      ];
    }
  }
}
