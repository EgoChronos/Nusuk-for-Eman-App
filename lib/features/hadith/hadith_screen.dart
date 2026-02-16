import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dedication_footer.dart';
import '../../data/models/hadith.dart';
import '../../data/notification_data.dart';

/// Hadith screen — curated collection by category
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  String _selectedCategory = 'patience';

  // Use shared data
  List<HadithCategory> get _categories => NotificationData.hadithCategories;
  List<Hadith> get _allHadiths => NotificationData.allHadiths;

  List<Hadith> get _filteredHadiths =>
      _allHadiths.where((h) => h.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'أحاديث نبوية',
          style: TextStyle(fontFamily: 'Amiri', fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          // Category tabs
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    label: Text(
                      cat.nameAr,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat.id),
                  ),
                );
              },
            ),
          ),

          // Hadith cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredHadiths.length,
              itemBuilder: (context, index) {
                final hadith = _filteredHadiths[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arabic text
                        Text(
                          hadith.textArabic,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            height: 1.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Divider(height: 24),
                        // English translation
                        Text(
                          hadith.textEnglish,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Source
                        Text(
                          '— ${hadith.source}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const DedicationFooter(),
        ],
      ),
    );
  }
}


