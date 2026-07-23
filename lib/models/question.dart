class Question {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String? verseOrHadithText;

  Question({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.verseOrHadithText,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = List<String>.from(json['options'] as List);
    final slicedOptions = rawOptions.take(3).toList();
    return Question(
      id: json['id'] as String,
      category: json['category'] as String,
      question: json['question'] as String,
      options: slicedOptions,
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String,
      verseOrHadithText: json['verseOrHadithText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'verseOrHadithText': verseOrHadithText,
    };
  }

  Question shuffleOptions() {
    final String correctOptionText = options[correctAnswerIndex];
    final List<String> shuffledOptions = List<String>.from(options)..shuffle();
    final int newCorrectIndex = shuffledOptions.indexOf(correctOptionText);

    return Question(
      id: id,
      category: category,
      question: question,
      options: shuffledOptions,
      correctAnswerIndex: newCorrectIndex,
      explanation: explanation,
      verseOrHadithText: verseOrHadithText,
    );
  }
}
