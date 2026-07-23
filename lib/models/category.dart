import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int totalLevels;
  
  // Dynamic fields that will be updated from local storage
  int currentLevel;
  bool isLocked;
  int score;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.totalLevels = 5,
    this.currentLevel = 1,
    this.isLocked = true,
    this.score = 0,
  });

  // Create a copy of the category with updated storage values
  Category copyWith({
    int? currentLevel,
    bool? isLocked,
    int? score,
  }) {
    return Category(
      id: id,
      name: name,
      description: description,
      icon: icon,
      color: color,
      totalLevels: totalLevels,
      currentLevel: currentLevel ?? this.currentLevel,
      isLocked: isLocked ?? this.isLocked,
      score: score ?? this.score,
    );
  }

  // Predefined default categories
  static List<Category> get defaultCategories {
    return [
      Category(
        id: 'quran',
        name: 'علوم القرآن',
        description: 'تفسير الآيات، أسباب النزول، وعلوم القرآن الكريم',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF00AFA3), // Soft Electric Teal
        isLocked: false, // First category is unlocked by default
      ),
      Category(
        id: 'aqeedah',
        name: 'العقيدة الإسلامية',
        description: 'أركان الإيمان، التوحيد، وأصول العقيدة الصحيحة',
        icon: Icons.shield_rounded,
        color: const Color(0xFF0369A1), // Sky Blue
        isLocked: true,
      ),
      Category(
        id: 'fiqh',
        name: 'الفقه والشريعة',
        description: 'أحكام العبادات، المعاملات، والطهارة والصلاة',
        icon: Icons.gavel_rounded,
        color: const Color(0xFFB45309), // Amber/Brown
        isLocked: true,
      ),
      Category(
        id: 'hadith',
        name: 'الحديث الشريف',
        description: 'الأحاديث النبوية الشريفة، صحيح البخاري ومسلم',
        icon: Icons.star_rounded,
        color: const Color(0xFF4338CA), // Indigo
        isLocked: true,
      ),
      Category(
        id: 'seerah',
        name: 'السيرة النبوية',
        description: 'حياة النبي صلى الله عليه وسلم، الغزوات الشريفة، والشمائل النبوية',
        icon: Icons.history_edu_rounded,
        color: const Color(0xFF65A30D), // Lime/Olive
        isLocked: true,
      ),
      Category(
        id: 'history',
        name: 'التاريخ والخلفاء',
        description: 'سير الخلفاء الراشدين، معارك الأمة الفاصلة، وإنجازات الحضارة',
        icon: Icons.castle_rounded,
        color: const Color(0xFF8B5CF6), // Royal Purple/Indigo
        isLocked: true,
      ),
      Category(
        id: 'enc_caliphs',
        name: 'عهد الخلفاء الراشدين',
        description: 'تاريخ خلافة أبي بكر وعمر وعثمان وعلي رضي الله عنهم أجمعين',
        icon: Icons.gavel_rounded,
        color: const Color(0xFFF59E0B), // Amber
        totalLevels: 10,
        isLocked: false, // First encyclopedia category is unlocked by default!
      ),
      Category(
        id: 'enc_dynasties',
        name: 'الدولة الأموية والعباسية',
        description: 'عصر الفتوحات الكبرى والتطور التاريخي للدولة الإسلامية',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF3B82F6), // Blue
        totalLevels: 10,
        isLocked: true,
      ),
      Category(
        id: 'enc_battles',
        name: 'الفتوحات والمعارك الكبرى',
        description: 'معارك المسلمين الفاصلة مثل اليرموك والقادسية وفتح الأندلس',
        icon: Icons.shield_rounded,
        color: const Color(0xFFEF4444), // Red
        totalLevels: 10,
        isLocked: true,
      ),
      Category(
        id: 'enc_scholars',
        name: 'العلماء والنهضة العلمية',
        description: 'سير علماء المسلمين ومخترعيهم وإسهاماتهم العلمية الخالدة',
        icon: Icons.school_rounded,
        color: const Color(0xFF8B5CF6), // Purple
        totalLevels: 10,
        isLocked: true,
      ),
      Category(
        id: 'enc_companions',
        name: 'سير الصحابة والأصحاب',
        description: 'حياة الصحابة الكرام وقصص تضحياتهم في نصرة الإسلام',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF10B981), // Emerald Green
        totalLevels: 10,
        isLocked: true,
      ),
    ];
  }
}
