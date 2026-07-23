import 'package:flutter/material.dart';

class ScholarRank {
  final String title;
  final String icon;
  final int minPoints;
  final int maxPoints;
  final Color color;

  ScholarRank({
    required this.title,
    required this.icon,
    required this.minPoints,
    required this.maxPoints,
    required this.color,
  });

  static List<ScholarRank> get ranks => [
        ScholarRank(
          title: 'طالب مبتدئ',
          icon: '📚',
          minPoints: 0,
          maxPoints: 99,
          color: const Color(0xFF94A3B8), // Slate
        ),
        ScholarRank(
          title: 'باحث مجتهد',
          icon: '✍️',
          minPoints: 100,
          maxPoints: 299,
          color: const Color(0xFF3B82F6), // Blue
        ),
        ScholarRank(
          title: 'فارس المنارة',
          icon: '⚡',
          minPoints: 300,
          maxPoints: 599,
          color: const Color(0xFF14B8A6), // Teal
        ),
        ScholarRank(
          title: 'العلاّمة الصغير',
          icon: '🌟',
          minPoints: 600,
          maxPoints: 999,
          color: const Color(0xFF8B5CF6), // Purple
        ),
        ScholarRank(
          title: 'المفكر القدير',
          icon: '🏆',
          minPoints: 1000,
          maxPoints: 999999, // Infinite
          color: const Color(0xFFF59E0B), // Gold
        ),
      ];

  static ScholarRank getRank(int points) {
    return ranks.firstWhere(
      (r) => points >= r.minPoints && points <= r.maxPoints,
      orElse: () => ranks.first,
    );
  }

  static ScholarRank? getNextRank(ScholarRank currentRank) {
    final index = ranks.indexOf(currentRank);
    if (index >= 0 && index < ranks.length - 1) {
      return ranks[index + 1];
    }
    return null; // Top rank reached
  }

  static double getProgressToNext(int points, ScholarRank currentRank) {
    final nextRank = getNextRank(currentRank);
    if (nextRank == null) return 1.0; // Max rank reached
    
    final totalRange = nextRank.minPoints - currentRank.minPoints;
    final currentProgress = points - currentRank.minPoints;
    return (currentProgress / totalRange).clamp(0.0, 1.0);
  }

  static String getProgressLabel(int points, ScholarRank currentRank) {
    final nextRank = getNextRank(currentRank);
    if (nextRank == null) return 'لقد بلغت الرتبة القصوى 🎉';
    
    final pointsNeeded = nextRank.minPoints - points;
    return 'متبقي $pointsNeeded ن للرتبة التالية: ${nextRank.title}';
  }
}
