import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/dedication_footer.dart';
import '../../core/widgets/reward_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/models/dhikr.dart';
import '../../data/sources/hive_storage.dart';
import '../../data/notification_data.dart';

/// Dhikr categories and tasbeeh counter
class DhikrScreen extends ConsumerStatefulWidget {
  final HiveStorage storage;

  const DhikrScreen({super.key, required this.storage});

  @override
  ConsumerState<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends ConsumerState<DhikrScreen> {
  String _selectedCategory = 'morning';

  // Use shared data
  List<DhikrCategory> get _categories => NotificationData.dhikrCategories;
  List<Dhikr> get _allDhikr => NotificationData.allDhikr;

  List<Dhikr> get _filteredDhikr =>
      _allDhikr.where((d) => d.category == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();
    _checkDailyReset();
  }

  /// Auto-reset: if the day has changed since the last reset, clear per-item counts.
  void _checkDailyReset() {
    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;
    final lastReset = widget.storage.getLastDhikrResetDay();
    if (lastReset == null || lastReset != today) {
      widget.storage.clearAllDhikrCounts();
      widget.storage.setLastDhikrResetDay(today);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الأذكار',
          style: TextStyle(fontFamily: 'Amiri', fontSize: 22),
        ),
        actions: [
          // Tasbeeh counter button
          IconButton(
            onPressed: () => _openTasbeeh(context),
            icon: const Text('📿', style: TextStyle(fontSize: 24)),
            tooltip: 'Tasbeeh Counter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
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
                    label: Text(
                      '${cat.icon} ${cat.nameArabic}',
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

          // Daily reset info note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 13, color: AppColors.textSubtle),
                const SizedBox(width: 4),
                Text(
                  widget.storage.getLanguage() == 'ar'
                      ? 'يُعاد تعيين العدّادات تلقائيًا كل يوم'
                      : 'Counters reset automatically each day',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSubtle, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Dhikr list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredDhikr.length,
              itemBuilder: (context, index) {
                final dhikr = _filteredDhikr[index];
                final count = widget.storage.getDhikrCount('${dhikr.id}');
                final progress = dhikr.targetCount > 0
                    ? (count / dhikr.targetCount).clamp(0.0, 1.0)
                    : 0.0;
                final isComplete = count >= dhikr.targetCount;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arabic text
                        Text(
                          dhikr.textArabic,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            height: 1.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dhikr.textEnglish,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (dhikr.reference != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            dhikr.reference!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accent,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Progress + count + reset
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppColors.divider,
                                  valueColor: AlwaysStoppedAnimation(
                                    isComplete ? Colors.green : AppColors.accent,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$count / ${dhikr.targetCount}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isComplete ? Colors.green : AppColors.primary,
                              ),
                            ),
                            // Manual reset button
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                onPressed: () async {
                                  await widget.storage.setDhikrCount('${dhikr.id}', 0);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.refresh, color: AppColors.textSubtle),
                                tooltip: 'Reset counter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Tap to count
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Increment per-item counter
                              await widget.storage
                                  .setDhikrCount('${dhikr.id}', count + 1);
                              // Increment global lifetime counter
                              await widget.storage.incrementTotalDhikr();
                              
                              // Sync to Supabase
                              try {
                                ref.read(supabaseServiceProvider)
                                   .incrementStats(dhikrCount: 1);
                              } catch (_) {}

                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isComplete ? Colors.green : AppColors.primary,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              isComplete ? '✓ Completed — tap for more' : 'Tap to count',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Donate reward button
          RewardButton(
            label: 'إهداء الثواب لـ ${AppStrings.dedicatedName} 🤲',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم إهداء الثواب 🤍',
                    textDirection: TextDirection.rtl,
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const DedicationFooter(),
        ],
      ),
    );
  }

  void _openTasbeeh(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasbeehScreen(storage: widget.storage),
      ),
    );
  }
}

/// Digital tasbeeh counter with haptic feedback
class TasbeehScreen extends ConsumerStatefulWidget {
  final HiveStorage storage;

  const TasbeehScreen({super.key, required this.storage});

  @override
  ConsumerState<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends ConsumerState<TasbeehScreen> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.storage.getTasbeehCount();
  }

  void _increment() async {
    HapticFeedback.lightImpact();
    await widget.storage.incrementTasbeeh();
    
    // Sync to Supabase
    try {
      ref.read(supabaseServiceProvider)
          .incrementStats(dhikrCount: 1);
    } catch (_) {}

    setState(() => _count++);
  }

  void _reset() {
    setState(() => _count = 0);
    widget.storage.setDhikrCount('tasbeeh_session', 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'تسبيح',
          style: TextStyle(fontFamily: 'Amiri', fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_count',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w300,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سبحان الله',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            // Large tap button
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.touch_app,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            RewardButton(
              label: 'إهداء الثواب لروحها 🤲',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إهداء الثواب 🤍',
                        textDirection: TextDirection.rtl),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const DedicationFooter(),
          ],
        ),
      ),
    );
  }
}
