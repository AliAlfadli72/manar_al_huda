import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import 'storage_service.dart';

class QuranApiService {
  static const String baseUrl = 'https://api.alquran.cloud/v1';

  final StorageService _storageService;

  QuranApiService(this._storageService);

  static const List<String> arabSurahs = [
    'سورة الفاتحة', 'سورة البقرة', 'سورة آل عمران', 'سورة النساء', 'سورة المائدة',
    'سورة الأنعام', 'سورة الأعراف', 'سورة الأنفال', 'سورة التوبة', 'سورة يونس',
    'سورة هود', 'سورة يوسف', 'سورة الرعد', 'سورة إبراهيم', 'سورة الحجر',
    'سورة النحل', 'سورة الإسراء', 'سورة الكهف', 'سورة مريم', 'سورة طه',
    'سورة الأنبياء', 'سورة الحج', 'سورة المؤمنون', 'سورة النور', 'سورة الفرقان',
    'سورة الشعراء', 'سورة النمل', 'سورة القصص', 'سورة العنكبوت', 'سورة الروم',
    'سورة لقمان', 'سورة السجدة', 'سورة الأحزاب', 'سورة سبأ', 'سورة فاطر',
    'سورة يس', 'سورة الصافات', 'سورة ص', 'سورة الزمر', 'سورة غافر',
    'سورة فصلت', 'سورة الشورى', 'سورة الزخرف', 'سورة الدخان', 'سورة الجاثية',
    'سورة الأحقاف', 'سورة محمد', 'سورة الفتح', 'سورة الحجرات', 'سورة ق',
    'سورة الذاريات', 'سورة الطور', 'سورة النجم', 'سورة القمر', 'سورة الرحمن',
    'سورة الواقعة', 'سورة الحديد', 'سورة المجادلة', 'سورة الحشر', 'سورة الممتحنة',
    'سورة الصف', 'سورة الجمعة', 'سورة المنافقون', 'سورة التغابن', 'سورة الطلاق',
    'سورة التحريم', 'سورة الملك', 'سورة القلم', 'سورة الحاقة', 'سورة المعارج',
    'سورة نوح', 'سورة الجن', 'سورة المزمل', 'سورة المدثر', 'سورة القيامة',
    'سورة الإنسان', 'سورة المرسلات', 'سورة النبأ', 'سورة النازعات', 'سورة عبس',
    'سورة التكوير', 'سورة الانفطار', 'سورة المطففين', 'سورة الانشقاق', 'سورة البروج',
    'سورة الطارق', 'سورة الأعلى', 'سورة الغاشية', 'سورة الفجر', 'سورة البلد',
    'سورة الشمس', 'سورة الليل', 'سورة الضحى', 'سورة الشرح', 'سورة التين',
    'سورة العلق', 'سورة القدر', 'سورة البينة', 'سورة الزلزلة', 'سورة العاديات',
    'سورة القارعة', 'سورة التكاثر', 'سورة العصر', 'سورة الهمزة', 'سورة الفيل',
    'سورة قريش', 'سورة الماعون', 'سورة الكوثر', 'سورة الكافرون', 'سورة النصر',
    'سورة المسد', 'سورة الإخلاص', 'سورة الفلق', 'سورة الناس'
  ];

  // List of famous Ayah numbers (global index in Quran 1-6236) to fetch
  static const List<Map<String, dynamic>> famousAyat = [
    {
      'globalId': 262, // Al-Baqarah: 255 (Ayat Al-Kursi)
      'surahName': 'سورة البقرة',
      'wrongSurahs': ['سورة آل عمران', 'سورة النساء', 'سورة المائدة'],
      'keywords': 'آية الكرسي هي أعظم آية، تدل على توحيد الله وعظمته وسلطانه',
    },
    {
      'globalId': 190, // Al-Baqarah: 183 (Fasting)
      'surahName': 'سورة البقرة',
      'wrongSurahs': ['سورة الأعراف', 'سورة التوبة', 'سورة يونس'],
      'keywords': 'فرض الصيام على المؤمنين لتحقيق التقوى والعبودية لله',
    },
    {
      'globalId': 2073, // Al-Isra: 1 (Isra & Mi'raj)
      'surahName': 'سورة الإسراء',
      'wrongSurahs': ['سورة الكهف', 'سورة النور', 'سورة الفرقان'],
      'keywords': 'الإسراء برسول الله من المسجد الحرام إلى المسجد الأقصى ليلاً',
    },
    {
      'globalId': 6125, // Al-Qadr: 1 (Laylat Al-Qadr)
      'surahName': 'سورة القدر',
      'wrongSurahs': ['سورة العلق', 'سورة البينة', 'سورة الضحى'],
      'keywords': 'إنزال القرآن الكريم في ليلة القدر المباركة التي هي خير من ألف شهر',
    },
    {
      'globalId': 6208, // Al-Kawthar: 1
      'surahName': 'سورة الكوثر',
      'wrongSurahs': ['سورة الماعون', 'سورة القارعة', 'سورة النصر'],
      'keywords': 'إعطاء النبي صلى الله عليه وسلم نهر الكوثر في الجنة وتعويض شانئيه بالبتر',
    },
    {
      'globalId': 6222, // Al-Ikhlas: 1
      'surahName': 'سورة الإخلاص',
      'wrongSurahs': ['سورة الفلق', 'سورة الناس', 'سورة المسد'],
      'keywords': 'التوحيد الخالص لله وتنزيهه سبحانه عن الشريك والولد صاحباً وولدًا',
    },
    {
      'globalId': 1, // Al-Fatihah: 1
      'surahName': 'سورة الفاتحة',
      'wrongSurahs': ['سورة البقرة', 'سورة آل عمران', 'سورة يس'],
      'keywords': 'افتتاح كتاب الله وحمده والثناء عليه والدعاء بالهداية للصراط المستقيم',
    },
    {
      'globalId': 3706, // Ya-Sin: 1
      'surahName': 'سورة يس',
      'wrongSurahs': ['سورة الصافات', 'سورة الصاف', 'سورة الدخان'],
      'keywords': 'إثبات رسالة النبي صلى الله عليه وسلم وإنذار الغافلين وبيان قدرة الله بالبعث',
    },
    {
      'globalId': 5249, // Al-Mulk: 1
      'surahName': 'سورة الملك',
      'wrongSurahs': ['سورة القلم', 'سورة الحاقة', 'سورة المعارج'],
      'keywords': 'إثبات عظمة ملك الله وخلقه للسماوات وابتلاء العباد بالموت والحياة',
    },
    {
      'globalId': 2140, // Al-Kahf: 1
      'surahName': 'سورة الكهف',
      'wrongSurahs': ['سورة مريم', 'سورة طه', 'سورة الأنبياء'],
      'keywords': 'حمد الله على إنزال الكتاب المستقيم لإنذار الكافرين وتبشير المؤمنين بالجنة',
    },
    {
      'globalId': 4634, // Al-Hujurat: 10
      'surahName': 'سورة الحجرات',
      'wrongSurahs': ['سورة المجادلة', 'سورة الحشر', 'سورة الممتحنة'],
      'keywords': 'تقرير الأخوة الإيمانية بين المسلمين ووجوب الصلح والإصلاح بين المتخاصمين',
    },
    {
      'globalId': 3482, // Luqman: 13
      'surahName': 'سورة لقمان',
      'wrongSurahs': ['سورة السجدة', 'سورة الروم', 'سورة العنكبوت'],
      'keywords': 'وصية لقمان لابنه بوجوب التوحيد والتحذير من الشرك بالله باعتباره ظلماً عظيماً',
    },
    {
      'globalId': 5092, // Al-Hadid: 20
      'surahName': 'سورة الحديد',
      'wrongSurahs': ['سورة الواقعة', 'سورة المجادلة', 'سورة التغابن'],
      'keywords': 'ضرب المثل للحياة الدنيا بماء الغيث وما يعقبه من بهجة ثم فناء وزوال سريع',
    },
    {
      'globalId': 5218, // Al-Hashr: 21
      'surahName': 'سورة الحشر',
      'wrongSurahs': ['سورة الصف', 'سورة الجمعة', 'سورة المنافقون'],
      'keywords': 'تأثير القرآن الكريم العظيم وخشوعه وتصدعه لو نزل على جبل صلب',
    },
    {
      'globalId': 1190, // Al-Anfal: 60
      'surahName': 'سورة الأنفال',
      'wrongSurahs': ['سورة التوبة', 'سورة الفتح', 'سورة الأحزاب'],
      'keywords': 'الأمر بإعداد القوة والاستعداد لترهيب أعداء الله وأعداء المسلمين',
    }
  ];

  /// Fetches a dynamic question based on a random famous Ayah
  Future<Question> fetchDynamicQuranQuestion(int level) async {
    final random = Random();
    
    // 50% chance to fetch from any of the 6,236 verses in the entire Quran
    final bool isAnyVerse = random.nextBool();

    if (isAnyVerse) {
      int globalId = random.nextInt(6236) + 1; // 1 to 6236
      final askedList = _storageService.getAskedQuestions('quran');
      
      // Try up to 5 times to avoid asking a recently asked random verse
      for (int i = 0; i < 5; i++) {
        if (!askedList.contains('dyn_quran_all_$globalId')) break;
        globalId = random.nextInt(6236) + 1;
      }
      
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/ayah/$globalId/editions/quran-simple,ar.muyassar'),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded['code'] == 200 && decoded['data'] is List) {
            final dataList = decoded['data'] as List;
            final cleanText = dataList[0]['text'] as String;
            final tafsirText = dataList[1]['text'] as String;
            final surahNameFromApi = dataList[0]['surah']['name'] as String;
            final int numberInSurah = dataList[0]['numberInSurah'] as int;

            // Filter out the correct Surah from our 114 list, shuffle and take 2 distractors
            final wrongSurahs = arabSurahs.where((s) => s != surahNameFromApi).toList()..shuffle(random);
            final distractors = wrongSurahs.take(2).toList();

            final options = [surahNameFromApi, ...distractors]..shuffle(random);
            final correctIndex = options.indexOf(surahNameFromApi);

            final Question question = Question(
              id: 'dyn_quran_all_$globalId',
              category: 'quran',
              question: 'في أي سورة وردت هذه الآية الكريمة؟ (رقم الآية: $numberInSurah)',
              options: options,
              correctAnswerIndex: correctIndex,
              explanation: 'هذه الآية الكريمة هي آية رقم $numberInSurah في $surahNameFromApi. وتفسيرها الميسر: $tafsirText \n(المصدر: التفسير الميسر - مجمع الملك فهد)',
              verseOrHadithText: '«$cleanText»',
            );
            await _storageService.markQuestionAsAsked('quran', question.id);
            return question;
          }
        }
      } catch (e) {
        // Fallback to famous ayat if request fails or offline
      }
    }

    // Otherwise, pick one of the famous verses (or fallback if the above failed)
    final askedList = _storageService.getAskedQuestions('quran');
    List<Map<String, dynamic>> availableItems = famousAyat
        .where((item) => !askedList.contains('dyn_quran_${item['globalId']}_0') &&
                         !askedList.contains('dyn_quran_${item['globalId']}_1'))
        .toList();

    // If all items have been asked, reset the history
    if (availableItems.isEmpty) {
      await _storageService.clearAskedQuestions('quran');
      availableItems = List<Map<String, dynamic>>.from(famousAyat);
    }

    final item = availableItems[random.nextInt(availableItems.length)];
    final globalId = item['globalId'] as int;

    final wrongSurahsList = List<String>.from(item['wrongSurahs'] as List);
    final keywords = item['keywords'] as String;

    try {
      // Fetch text and translation/tafsir in one call
      final response = await http.get(
        Uri.parse('$baseUrl/ayah/$globalId/editions/quran-simple,ar.muyassar'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['code'] == 200 && decoded['data'] is List) {
          final dataList = decoded['data'] as List;
          final cleanText = dataList[0]['text'] as String;
          final tafsirText = dataList[1]['text'] as String;
          final surahNameFromApi = dataList[0]['surah']['name'] as String;

          // We will decide between two types of questions:
          // Type 0: In which Surah is this verse?
          // Type 1: What is the Tafsir/meaning of this verse?
          int questionType = random.nextInt(2);
          final String qId = 'dyn_quran_${globalId}_$questionType';

          // If that specific type has already been asked, switch type
          if (askedList.contains(qId)) {
            questionType = 1 - questionType;
          }

          if (questionType == 0) {
            final options = [surahNameFromApi, ...wrongSurahsList.take(2)]..shuffle(random);
            final correctIndex = options.indexOf(surahNameFromApi);

            final Question question = Question(
              id: 'dyn_quran_${globalId}_0',
              category: 'quran',
              question: 'في أي سورة وردت هذه الآية الكريمة؟',
              options: options,
              correctAnswerIndex: correctIndex,
              explanation: 'هذه الآية الكريمة هي جزء من $surahNameFromApi. وتفسيرها الميسر: $tafsirText',
              verseOrHadithText: '«$cleanText»',
            );
            await _storageService.markQuestionAsAsked('quran', question.id);
            return question;
          } else {
            // Ask about meaning/interpretation
            final correctOption = keywords;
            final options = [
              correctOption,
              'بيان شروط قبول العبادات والطاعات وأهمية الدعاء والتوكل',
              'التحذير من الفتن وأحوال يوم القيامة والحساب والجزاء',
            ]..shuffle(random);
            final correctIndex = options.indexOf(correctOption);

            final Question question = Question(
              id: 'dyn_quran_${globalId}_1',
              category: 'quran',
              question: 'ما هو المعنى العام أو المقصد من هذه الآية الكريمة؟',
              options: options,
              correctAnswerIndex: correctIndex,
              explanation: 'التفسير الميسر للآية: $tafsirText \n(المصدر: التفسير الميسر)',
              verseOrHadithText: '«$cleanText»',
            );
            await _storageService.markQuestionAsAsked('quran', question.id);
            return question;
          }
        }
      }
      throw Exception('Failed to parse API response');
    } catch (e) {
      // Return a structured fallback question for the specific level if API fails/offline
      return _getFallbackQuranQuestion(level);
    }
  }

  Question _getFallbackQuranQuestion(int level) {
    final fallbacks = [
      Question(
        id: 'fallback_quran_1',
        category: 'quran',
        question: 'ما هي أعظم آية في القرآن الكريم؟',
        options: ['آية الكرسي', 'آية الدين', 'آخر آية في سورة البقرة'],
        correctAnswerIndex: 0,
        explanation: 'آية الكرسي (البقرة: 255) هي أعظم آية في كتاب الله لما تشمل عليه من معاني التوحيد والصفات العلية لله سبحانه وتعالى.',
        verseOrHadithText: '«اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...»',
      ),
      Question(
        id: 'fallback_quran_2',
        category: 'quran',
        question: 'ما هي السورة التي تشادل عن صاحبها في القبر حتى يغفر له؟',
        options: ['سورة الملك', 'سورة السجدة', 'سورة يس'],
        correctAnswerIndex: 0,
        explanation: 'ورد في الحديث الشريف أن سورة تبارك (الملك) هي ثلاثون آية شفعت لرجل حتى غفر له.',
        verseOrHadithText: '«تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ»',
      ),
      Question(
        id: 'fallback_quran_3',
        category: 'quran',
        question: 'ما هي السورة التي تعدل ثلث القرآن الكريم؟',
        options: ['سورة الإخلاص', 'سورة الفاتحة', 'سورة الكافرون'],
        correctAnswerIndex: 0,
        explanation: 'سورة الإخلاص تعدل ثلث القرآن في الأجر والموضوع، لأنها تمحضت لبيان صفة الرحمن وتوحيده.',
        verseOrHadithText: '«قُلْ هُوَ اللَّهُ أَحَدٌ * اللَّهُ الصَّمَدُ»',
      )
    ];

    final askedList = _storageService.getAskedQuestions('quran');
    final List<Question> available = fallbacks.where((q) => !askedList.contains(q.id)).toList();

    Question selected;
    if (available.isNotEmpty) {
      selected = available[Random().nextInt(available.length)];
    } else {
      selected = fallbacks[(level - 1) % fallbacks.length];
    }

    _storageService.markQuestionAsAsked('quran', selected.id);
    return selected;
  }
}
