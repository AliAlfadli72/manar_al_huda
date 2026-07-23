import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/library_data.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategoryId = 'books';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'books',
      'name': 'أمهات الكتب',
      'icon': Icons.auto_stories_rounded,
      'color': const Color(0xFFD97706), // Amber Gold
    },
    {
      'id': 'principles',
      'name': 'قواعد الشريعة',
      'icon': Icons.gavel_rounded,
      'color': const Color(0xFF00AFA3), // Electric Teal
    },
    {
      'id': 'seerah',
      'name': 'أطلس السيرة',
      'icon': Icons.map_rounded,
      'color': const Color(0xFF8B5CF6), // Purple
    },
    {
      'id': 'scholars',
      'name': 'أئمة الهدى',
      'icon': Icons.people_rounded,
      'color': const Color(0xFF2563EB), // Sapphire
    },
    {
      'id': 'sciences',
      'name': 'علوم الدين',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF10B981), // Emerald
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get filtered items based on current category and search query
  List<LibraryItem> _getFilteredItems() {
    final categoryItems = LibraryData.items
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList();

    if (_searchQuery.trim().isEmpty) {
      return categoryItems;
    }

    final query = _searchQuery.toLowerCase();
    return categoryItems.where((item) {
      final matchTitle = item.title.toLowerCase().contains(query);
      final matchContent = item.mainContent.toLowerCase().contains(query);
      final matchExplanation = item.explanation.toLowerCase().contains(query);
      final matchAuthor = item.authorName?.toLowerCase().contains(query) ?? false;
      return matchTitle || matchContent || matchExplanation || matchAuthor;
    }).toList();
  }

  // Copy text to clipboard and show snackbar
  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'تم نسخ $label بنجاح',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.0,
              ),
            ),
            const SizedBox(width: 8.0),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18.0),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.all(16.0),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();
    final activeColor = _categories.firstWhere((c) => c['id'] == _selectedCategoryId)['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Elegant light slate background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'مكتبة المنارة المعرفية',
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F172A),
            fontSize: 19.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Search & Quote of the Day)
            _buildTopBar(activeColor),

            // Horizontal Categories Selector
            _buildCategoryTabs(),
            const SizedBox(height: 12.0),

            // Main Content Area
            Expanded(
              child: filteredItems.isEmpty
                  ? _buildEmptyState()
                  : _selectedCategoryId == 'books' && _searchQuery.trim().isEmpty
                      ? _buildBookshelfLayout(filteredItems)
                      : _buildStandardLayout(filteredItems, activeColor),
            ),
          ],
        ),
      ),
    );
  }

  // Top Bar Container
  Widget _buildTopBar(Color activeColor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Box
          Container(
            height: 48.0,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث عن الكتب، العلماء، أو الفوائد الشرعية...',
                hintStyle: GoogleFonts.cairo(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12.5,
                ),
                prefixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18.0),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                suffixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00AFA3), size: 22.0),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              style: GoogleFonts.cairo(
                fontSize: 14.5,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Inspiring Quote of the Day
          GestureDetector(
            onLongPress: () {
              _copyToClipboard(
                context,
                '«مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ» - حديث شريف',
                'درة اليوم',
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    activeColor.withOpacity(0.85),
                    const Color(0xFF0F172A).withOpacity(0.9),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.1),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18.0),
                    onPressed: () {
                      _copyToClipboard(
                        context,
                        '«مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ» - حديث شريف',
                        'درة اليوم',
                      );
                    },
                    tooltip: 'نسخ درة اليوم',
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'درة اليوم المعرفية ✧',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFFDE68A), // Light Amber Gold
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 3.5),
                        Text(
                          '«مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ»',
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFDE68A), size: 20.0),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),
        ],
      ),
    );
  }

  // Categories Tab Row
  Widget _buildCategoryTabs() {
    return Container(
      height: 48.0,
      margin: const EdgeInsets.only(top: 12.0),
      child: ListView.builder(
        itemCount: _categories.length,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat['id'] == _selectedCategoryId;
          final color = cat['color'] as Color;

          return GestureDetector(
            onTap: () {
              if (_selectedCategoryId == cat['id']) return;
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategoryId = cat['id'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    )
                  else
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.01),
                      blurRadius: 4.0,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? color : const Color(0xFF64748B),
                    size: 18.0,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    cat['name'] as String,
                    style: GoogleFonts.cairo(
                      color: isSelected ? color : const Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 1. Bookshelf Layout (for Books Category)
  Widget _buildBookshelfLayout(List<LibraryItem> items) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'أمهات الكتب الإسلامية المعرفية 📚',
              style: GoogleFonts.cairo(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 8.0),

          // Horizontal shelf
          Container(
            height: 250.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Visual shelf wood bar
                Positioned(
                  bottom: 25.0,
                  left: 10.0,
                  right: 10.0,
                  child: Container(
                    height: 16.0,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF4C1D95)], // Violet wood shelf
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.2),
                          blurRadius: 10.0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),

                // Books List
                Positioned.fill(
                  child: ListView.builder(
                    itemCount: items.length,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemBuilder: (context, index) {
                      final book = items[index];
                      // Choose a different gradient for each book
                      final gradients = [
                        [const Color(0xFF9A3412), const Color(0xFF431407)], // Dark rust
                        [const Color(0xFF065F46), const Color(0xFF022C22)], // Dark emerald
                        [const Color(0xFF1E3A8A), const Color(0xFF0F172A)], // Deep Navy
                        [const Color(0xFF6B21A8), const Color(0xFF3B0764)], // Dark purple
                        [const Color(0xFFB45309), const Color(0xFF78350F)], // Dark amber
                      ];
                      final bookGradient = gradients[index % gradients.length];

                      return _buildBookCover(book, bookGradient);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15.0),

          // Vertical lists for detailed exploration
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'استكشاف تفاصيل ومراجع الكتب:',
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 8.0),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemBuilder: (context, index) {
              final book = items[index];
              return _buildBookRowCard(book, const Color(0xFFD97706));
            },
          ),
        ],
      ),
    );
  }

  // Interactive Book Cover component
  Widget _buildBookCover(LibraryItem book, List<Color> colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showItemDetailsSheet(context, book);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        width: 130.0,
        height: 180.0,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.centerRight,
              end: Alignment.centerLeft, // darker left edge to simulate 3D spine
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16.0),
              bottomRight: Radius.circular(16.0),
              topLeft: Radius.circular(4.0),
              bottomLeft: Radius.circular(4.0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.3),
                blurRadius: 8.0,
                offset: const Offset(4, 6),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFDE68A).withOpacity(0.2), // soft gold highlight
              width: 0.8,
            ),
          ),
          child: Stack(
            children: [
              // 3D book spine line effect on the left
              Positioned(
                left: 8.0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1.5,
                  color: Colors.white10,
                ),
              ),

              // Gold frame ornament inside cover
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.25), // gold border
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),

              // Title and author details
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gold star emblem
                      Icon(Icons.auto_stories_rounded, color: const Color(0xFFF59E0B).withOpacity(0.4), size: 16.0),
                      
                      // Book Title
                      Expanded(
                        child: Center(
                          child: Text(
                            book.title.split(' (').first,
                            style: GoogleFonts.amiri(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Author label
                      Text(
                        book.authorName?.split(' ').last ?? '',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFFDE68A),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
    );
  }

  // Book vertical list card helper
  Widget _buildBookRowCard(LibraryItem book, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.015),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          onTap: () => _showItemDetailsSheet(context, book),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, color: color.withOpacity(0.7), size: 14.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF0F172A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'تأليف: ${book.authorName}',
                        style: GoogleFonts.cairo(
                          color: color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        book.mainContent,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF64748B),
                          fontSize: 12.0,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: color, size: 22.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Standard Grid/List Layout (for all other categories)
  Widget _buildStandardLayout(List<LibraryItem> items, Color color) {
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.015),
                blurRadius: 8.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: InkWell(
              onTap: () => _showItemDetailsSheet(context, item),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top row: Type Icon + Title
                    Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: color.withOpacity(0.7), size: 14.0),
                        const Spacer(),
                        
                        // Tag for date/era if present
                        if (item.eventDate != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              item.eventDate!,
                              style: GoogleFonts.cairo(
                                color: color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A),
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Container(
                          padding: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _categories.firstWhere((c) => c['id'] == _selectedCategoryId)['icon'] as IconData,
                            color: color,
                            size: 16.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // Main excerpt
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        item.mainContent,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF475569),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  // 3. Empty search result view
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 64.0),
            const SizedBox(height: 15.0),
            Text(
              'لم نجد نتائج مطابقة لبحثك',
              style: GoogleFonts.cairo(
                color: const Color(0xFF0F172A),
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5.0),
            Text(
              'تأكد من كتابة الكلمات بشكل صحيح أو جرب استخدام كلمات أخرى.',
              style: GoogleFonts.cairo(
                color: const Color(0xFF64748B),
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 4. Interactive Bottom Sheet for Item Details
  void _showItemDetailsSheet(BuildContext context, LibraryItem item) {
    final activeColor = _categories.firstWhere((c) => c['id'] == _selectedCategoryId)['color'] as Color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (sheetContext) {
        return LibraryItemDetailModal(
          item: item,
          activeColor: activeColor,
          copyCallback: (text, label) => _copyToClipboard(context, text, label),
        );
      },
    );
  }
}

// Stateful Widget to manage internal tabs of details bottom sheet
class LibraryItemDetailModal extends StatefulWidget {
  final LibraryItem item;
  final Color activeColor;
  final Function(String, String) copyCallback;

  const LibraryItemDetailModal({
    super.key,
    required this.item,
    required this.activeColor,
    required this.copyCallback,
  });

  @override
  State<LibraryItemDetailModal> createState() => _LibraryItemDetailModalState();
}

class _LibraryItemDetailModalState extends State<LibraryItemDetailModal> {
  int _activeTabIndex = 0;

  List<String> _getTabNames() {
    if (widget.item.categoryId == 'books') {
      return ['نبذة عن الكتاب', 'المؤلف والسيرة', 'درر مقتبسة'];
    } else if (widget.item.categoryId == 'scholars') {
      return ['السيرة والنشأة', 'الشيوخ والتلاميذ', 'أقواله المأثورة'];
    } else {
      return ['الشرح والبيان', 'الفوائد والدروس'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabNames();
    final height = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: height * 0.82,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.item.title,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF0F172A),
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        if (widget.item.authorName != null) ...[
                          const SizedBox(height: 2.0),
                          Text(
                            widget.item.authorName!,
                            style: GoogleFonts.cairo(
                              color: widget.activeColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else if (widget.item.eventDate != null) ...[
                          const SizedBox(height: 2.0),
                          Text(
                            'تاريخ الحدث: ${widget.item.eventDate}',
                            style: GoogleFonts.cairo(
                              color: widget.activeColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: widget.activeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.item.categoryId == 'books'
                          ? Icons.menu_book_rounded
                          : widget.item.categoryId == 'scholars'
                              ? Icons.people_rounded
                              : Icons.auto_awesome_rounded,
                      color: widget.activeColor,
                      size: 24.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),

              // Tab selector
              Container(
                height: 40.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: List.generate(tabs.length, (idx) {
                    // RTL arrangement: reverse mapping
                    final tabIdx = tabs.length - 1 - idx;
                    final isTabSelected = _activeTabIndex == tabIdx;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _activeTabIndex = tabIdx;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(3.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isTabSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9.0),
                            boxShadow: isTabSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withOpacity(0.05),
                                      blurRadius: 4.0,
                                      offset: const Offset(0, 1.5),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            tabs[tabIdx],
                            style: GoogleFonts.cairo(
                              color: isTabSelected ? widget.activeColor : const Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16.0),

              // Tab contents
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildActiveTabContent(),
                ),
              ),
              const SizedBox(height: 20.0),

              // Bottom Action button row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.activeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        elevation: 0,
                      ),
                      child: Text(
                        'تمت الاستفادة والرجوع',
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  
                  // Copy button
                  InkWell(
                    onTap: () {
                      final textToCopy = _getTextForActiveTab();
                      widget.copyCallback(textToCopy, tabs[_activeTabIndex]);
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      width: 50.0,
                      height: 50.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                      ),
                      child: const Icon(Icons.copy_rounded, color: Color(0xFF475569), size: 20.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Returns text representing active tab to copy
  String _getTextForActiveTab() {
    final item = widget.item;
    if (item.categoryId == 'books') {
      if (_activeTabIndex == 0) {
        return '${item.title}\nنبذة: ${item.mainContent}\nتفصيل: ${item.explanation}';
      } else if (_activeTabIndex == 1) {
        return 'المؤلف: ${item.authorName}\nالعصر: ${item.authorEra}\nالأهمية: ${item.bookImportance}';
      } else {
        return 'الفوائد والدرر المستخلصة من كتاب ${item.title}:\n' + item.takeaways.map((t) => '- $t').join('\n');
      }
    } else if (item.categoryId == 'scholars') {
      if (_activeTabIndex == 0) {
        return 'الترجمة: ${item.title}\nسيرته ونشأته: ${item.explanation}\nعمره وفترته: ${item.scholarLife}';
      } else if (_activeTabIndex == 1) {
        return 'تلاميذ وشيوخ ومؤلفات ${item.title}:\n${item.scholarTeachers}';
      } else {
        return 'من أقوال ومأثورات ${item.title}:\n${item.mainContent}\nالفوائد العلمية:\n' + item.takeaways.map((t) => '- $t').join('\n');
      }
    } else {
      if (_activeTabIndex == 0) {
        return '${item.title}\nالشرح والبيان: ${item.explanation}\nالمنطوق الرئيسي: ${item.mainContent}';
      } else {
        return 'الفوائد والدروس المستفادة من ${item.title}:\n' + item.takeaways.map((t) => '- $t').join('\n');
      }
    }
  }

  // Render tab content dynamically
  Widget _buildActiveTabContent() {
    final item = widget.item;

    if (item.categoryId == 'books') {
      // Books tabs content
      if (_activeTabIndex == 0) {
        // Tab 0: About Book
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionHeader('التعريف الميسر بالمصنف:'),
            _buildHighlightContentBox(item.mainContent),
            const SizedBox(height: 15.0),
            _buildSectionHeader('الشرح العلمي والتفصيلي:'),
            _buildNormalParagraph(item.explanation),
          ],
        );
      } else if (_activeTabIndex == 1) {
        // Tab 1: Author & Era
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionHeader('اسم المؤلف وعصره:'),
            _buildHighlightContentBox(
              'المصنف: ${item.authorName}\nالحقبة الزمنية: ${item.authorEra}',
            ),
            const SizedBox(height: 15.0),
            _buildSectionHeader('أهمية وقيمة الكتاب:'),
            _buildNormalParagraph(item.bookImportance ?? ''),
            const SizedBox(height: 15.0),
            _buildSectionHeader('تقسيم الكتاب وأبوابه الرئيسية:'),
            _buildNormalParagraph(item.bookChapters ?? ''),
          ],
        );
      } else {
        // Tab 2: Takeaways / Pearls
        return _buildTakeawaysList(item.takeaways);
      }
    } else if (item.categoryId == 'scholars') {
      // Scholars tabs content
      if (_activeTabIndex == 0) {
        // Tab 0: Biography
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionHeader('ترجمة العلم وحياته:'),
            _buildHighlightContentBox('اللقب: ${item.title}\nالحقبة والعمر: ${item.scholarLife}'),
            const SizedBox(height: 15.0),
            _buildSectionHeader('سيرته وتفاصيل نشأته وعلمه:'),
            _buildNormalParagraph(item.explanation),
          ],
        );
      } else if (_activeTabIndex == 1) {
        // Tab 1: Teachers & Works
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionHeader('شيوخه، تلامذته، وأبرز مؤلفاته:'),
            _buildNormalParagraph(item.scholarTeachers ?? ''),
          ],
        );
      } else {
        // Tab 2: Quotes / Takeaways
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionHeader('من درر وأقوال العلم المأثورة:'),
            _buildWisdomQuoteBox(item.mainContent),
            const SizedBox(height: 18.0),
            _buildSectionHeader('الدروس والفوائد من منهجه العلمي:'),
            _buildTakeawaysList(item.takeaways),
          ],
        );
      }
    } else {
      // General tabs (principles, seerah, sciences)
      if (_activeTabIndex == 0) {
        // Tab 0: Explanation
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionHeader('المفهوم الرئيسي والمنطوق الشرعي:'),
            _buildHighlightContentBox(item.mainContent),
            const SizedBox(height: 15.0),
            _buildSectionHeader('الشرح والبيان الموثق:'),
            _buildNormalParagraph(item.explanation),
          ],
        );
      } else {
        // Tab 1: Takeaways
        return _buildTakeawaysList(item.takeaways);
      }
    }
  }

  // Component Helper: Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          color: widget.activeColor,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  // Component Helper: Highlight Box
  Widget _buildHighlightContentBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: widget.activeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: widget.activeColor.withOpacity(0.15), width: 1.0),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: const Color(0xFF0F172A),
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          height: 1.6,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  // Component Helper: Wisdom Quote Box (Amiri Font, elegant styling)
  Widget _buildWisdomQuoteBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Elegant light amber
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.format_quote_rounded, color: Color(0xFFD97706), size: 24.0),
          ),
          Text(
            text,
            style: GoogleFonts.amiri(
              color: const Color(0xFF78350F), // Rich deep gold/brown
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const Align(
            alignment: Alignment.bottomLeft,
            child: Icon(Icons.format_quote_rounded, color: Color(0xFFD97706), size: 24.0),
          ),
        ],
      ),
    );
  }

  // Component Helper: Normal Paragraph
  Widget _buildNormalParagraph(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: const Color(0xFF475569),
          fontSize: 13.5,
          height: 1.65,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  // Component Helper: Takeaways Checklist list
  Widget _buildTakeawaysList(List<String> takeaways) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('الدروس والفوائد العملية للتطبيق والعمل:'),
        const SizedBox(height: 6.0),
        ...takeaways.map((takeaway) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    takeaway,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF334155),
                      fontSize: 13.0,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10.0),
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: widget.activeColor,
                  size: 18.0,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
