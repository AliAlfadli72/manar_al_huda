import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/question.dart';
import 'storage_service.dart';

class HadithApiService {
  // Base URL for HadeethEnc API
  static const String hadeethEncBaseUrl = 'https://hadeethenc.com/api/v1';

  final StorageService _storageService;

  HadithApiService(this._storageService);

  // Category 5 on HadeethEnc is "الفضائل والآداب" (Virtues and Manners), excellent for general Hadith trivia
  static const int encCategoryId = 5;

  List<String> _getHadithDistractors() {
    return [
      'أهمية إخلاص النية لله تعالى في السر والعلن وتصفية القلب.',
      'التحلي بالأخلاق الحسنة والرفق بالناس وكف الأذى عنهم.',
      'وجوب الصبر والثبات عند ملاقاة الشدائد والابتلاءات في سبيل الله.',
      'فضل صلة الأرحام وحسن الجوار والإحسان إلى الأقارب والفقراء.',
      'أهمية المشورة وأخذ بآراء أصحاب الخبرة في شؤون المسلمين.',
      'ضرورة التخطيط الجيد والاتخاذ بالأسباب مع التوكل التام على الله.',
      'بيان أهمية حفظ اللسان وتجنب نقل الكلام الذي يثير الفتن.',
      'التحلي بالرفق واللين في دعوة الناس إلى طريق الحق والخير.'
    ];
  }

  /// Fetches a dynamic Hadith question from HadeethEnc API.
  /// Falls back to pre-verified offline Hadiths if the API call fails or is offline.
  Future<Question> fetchDynamicHadithQuestion(int level) async {
    try {
      final random = Random();
      final int page = random.nextInt(10) + 1; // 1 to 10
      
      // Step 1: Fetch list of Hadiths from a random page
      final listResponse = await http.get(
        Uri.parse('$hadeethEncBaseUrl/hadeeths/list/?language=ar&category_id=$encCategoryId&per_page=30&page=$page'),
      ).timeout(const Duration(seconds: 5));

      if (listResponse.statusCode == 200) {
        final Map<String, dynamic> decodedList = json.decode(listResponse.body);
        if (decodedList['data'] is List && (decodedList['data'] as List).isNotEmpty) {
          final List<dynamic> data = decodedList['data'];
          
          final askedList = _storageService.getAskedQuestions('hadith');

          // Filter out recently asked Hadiths
          List<dynamic> availableHadiths = data
              .where((item) => !askedList.contains('online_hadith_${item['id']}'))
              .toList();

          if (availableHadiths.isEmpty) {
            await _storageService.clearAskedQuestions('hadith');
            availableHadiths = data;
          }

          final randomItem = availableHadiths[random.nextInt(availableHadiths.length)];
          final String hadithId = randomItem['id'].toString();

          // Step 2: Fetch details for this Hadith
          final detailResponse = await http.get(
            Uri.parse('$hadeethEncBaseUrl/hadeeths/one/?id=$hadithId&language=ar'),
          ).timeout(const Duration(seconds: 5));

          if (detailResponse.statusCode == 200) {
            final Map<String, dynamic> detail = json.decode(detailResponse.body);
            
            final String hadithText = detail['hadeeth'] ?? '';
            final String hadithTitle = detail['title'] ?? '';
            final String rawExplanation = detail['explanation'] ?? '';
            final String reference = detail['reference'] ?? 'صحيح البخاري ومسلم';
            final List<dynamic> hints = detail['hints'] ?? [];

            // The correct answer is the first hint of the Hadith
            String correctOption = 'العمل بالآداب الإسلامية النبوية وتطبيقها في الحياة اليومية';
            if (hints.isNotEmpty && hints[0].toString().trim().isNotEmpty) {
              correctOption = hints[0].toString().trim();
            } else if (hadithTitle.isNotEmpty) {
              correctOption = hadithTitle;
            }

            // Distractor options (Conceptually close and educational moral lessons)
            final distractorPool = _getHadithDistractors();
            final shuffledPool = distractorPool.where((ans) => ans != correctOption).toList()..shuffle(random);

            final List<String> distractors = [];
            if (shuffledPool.length >= 2) {
              distractors.addAll(shuffledPool.take(2));
            } else {
              distractors.addAll([
                'أهمية إخلاص النية لله تعالى في السر والعلن وتصفية القلب',
                'التحلي بالأخلاق الحسنة والرفق بالناس وكف الأذى عنهم'
              ]);
            }

            final List<String> options = [correctOption, ...distractors]..shuffle(random);
            final int correctIndex = options.indexOf(correctOption);

            final Question question = Question(
              id: 'online_hadith_$hadithId',
              category: 'hadith',
              question: 'ما هو التوجيه النبوي أو الفائدة الأساسية المستفادة من هذا الحديث الشريف؟',
              options: options,
              correctAnswerIndex: correctIndex,
              explanation: '$rawExplanation\n\n(المصدر: $reference)',
              verseOrHadithText: hadithText,
            );
            
            await _storageService.markQuestionAsAsked('hadith', question.id);
            return question;
          }
        }
      }
      throw Exception('Failed to load online Hadith list');
    } catch (e) {
      // Fallback
      return _getFallbackHadithQuestion(level);
    }
  }

  Question _getFallbackHadithQuestion(int level) {
    final random = Random();
    final List<Map<String, dynamic>> verifiedHadiths = [
      {
        'hadith': 'عَنْ أَبِي هُرَيْرَةَ رَضِيَ اللَّهُ عَنْهُ، أَنَّ رَسُولَ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ قَالَ: «مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ»',
        'question': 'ما الذي يرشدنا إليه الحديث الشريف فيما يتعلق بعبادة اللسان وحفظ الجوارح؟',
        'options': [
          'وجوب حفظ اللسان وقول الخير أو التزام الصمت كعلامة للإيمان',
          'الصمت مطلوب في جميع الأحوال حتى في إنكار المنكر',
          'جواز الحديث بأي كلام دون ضوابط أو قيود شرعية',
          'تفضيل العزلة الكاملة وعدم الاختلاط بالناس أبداً'
        ],
        'correctAnswerIndex': 0,
        'explanation': 'يرشدنا الحديث الشريف إلى أن حفظ اللسان وقول الخير أو السكوت هو شعبة عظيمة من شعب الإيمان بالله واليوم الآخر. (صحيح البخاري ومسلم)',
      },
      {
        'hadith': 'عَنْ أَمِيرِ الْمُؤْمِنِينَ أَبِي حَفْصٍ عُمَرَ بْنِ الْخَطَّابِ رَضِيَ اللَّهُ عَنْهُ قَالَ: سَمِعْتُ رَسُولَ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ يَقُولُ: «إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ...»',
        'question': 'ما هو الركن الأساسي لقبول العمل عند الله تبارك وتعالى استناداً للحديث؟',
        'options': [
          'وجود النية الصادقة والإخلاص لله تعالى',
          'موافقة العمل لرأي أغلبية الناس والمجتمع',
          'حجم العمل المالي وكثرة المظاهر الخارجية',
          'إتمام العمل في وقت سريع بغض النظر عن النية'
        ],
        'correctAnswerIndex': 0,
        'explanation': 'النية هي المعيار والميزان الباطني لتصحيح الأعمال وقبولها أو ردها عند الله تعالى. (متفق عليه)',
      },
      {
        'hadith': 'عَنْ أَبِي هُرَيْرَةَ رَضِيَ اللَّهُ عَنْهُ قَالَ: قَالَ رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ: «كَلِمَتَانِ حَبِيبَتَانِ إِلَى الرَّحْمَنِ، خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ...»',
        'question': 'ما هما الكلمتان اللتان أرشدنا إليهما الرسول صلى الله عليه وسلم في هذا الحديث الشريف؟',
        'options': [
          'سبحان الله وبحمده، سبحان الله العظيم',
          'الحمد لله حمداً كثيراً طيباً مباركاً فيه',
          'لا حول ولا قوة إلا بالله العلي العظيم',
          'أستغفر الله العظيم وأتوب إليه من كل ذنب'
        ],
        'correctAnswerIndex': 0,
        'explanation': 'الكلمتان هما: (سبحان الله وبحمده، سبحان الله العظيم) كما ورد في خاتمة صحيح البخاري، وهما تدلان على فضل التسبيح وسهولته وعظم أجره.',
      }
    ];

    final askedList = _storageService.getAskedQuestions('hadith');
    
    // Find unasked fallbacks
    final List<Map<String, dynamic>> availableHadiths = verifiedHadiths
        .where((h) => !askedList.contains('fallback_hadith_${verifiedHadiths.indexOf(h) + 1}'))
        .toList();

    Map<String, dynamic> item;
    int selectedIndex;
    if (availableHadiths.isNotEmpty) {
      item = availableHadiths[random.nextInt(availableHadiths.length)];
      selectedIndex = verifiedHadiths.indexOf(item) + 1;
    } else {
      selectedIndex = (level - 1) % verifiedHadiths.length + 1;
      item = verifiedHadiths[selectedIndex - 1];
    }

    final String qId = 'fallback_hadith_$selectedIndex';
    _storageService.markQuestionAsAsked('hadith', qId);

    return Question(
      id: qId,
      category: 'hadith',
      question: item['question'] as String,
      options: List<String>.from(item['options'] as List).take(3).toList(),
      correctAnswerIndex: item['correctAnswerIndex'] as int,
      explanation: item['explanation'] as String,
      verseOrHadithText: item['hadith'] as String,
    );
  }
}
