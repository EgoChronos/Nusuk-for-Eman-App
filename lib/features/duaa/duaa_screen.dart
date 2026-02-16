import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dedication_footer.dart';
import '../../core/widgets/reward_button.dart';
import '../../data/sources/hive_storage.dart';
import '../../data/notification_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'package:share_plus/share_plus.dart';

/// Duaa page — the emotional center of the app
class DuaaScreen extends StatefulWidget {
  final HiveStorage storage;
  const DuaaScreen({super.key, required this.storage});

  @override
  State<DuaaScreen> createState() => _DuaaScreenState();
}

class _DuaaScreenState extends State<DuaaScreen> {
  late int _duaaToday;
  late int _duaaTotal;

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  void _refreshCounts() {
    _duaaToday = widget.storage.getDuaaCountToday();
    _duaaTotal = widget.storage.getDuaaCount();
  }

  void _makeDuaa() async {
    await widget.storage.incrementDuaa();
    
    // Sync to Supabase
    if (mounted) {
      try {
        final supabase = ProviderScope.containerOf(context).read(supabaseServiceProvider);
        // Sync Duaa to its own global stat column
        await supabase.incrementStats(duaaCount: 1);
      } catch (e) {
        // Ignore provider errors or sync errors
      }
    }

    setState(() => _refreshCounts());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جزاك الله خيرًا 🤍', textDirection: TextDirection.rtl, textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareDuaa() {
    const text = 'اللهم اغفر لـ إيمان محمد طايع وارحمها، وعافها واعف عنها، وأكرم نزلها، ووسع مدخلها 🤍\n\n'
        'صدقة جارية لروحها - تطبيق "نور لإيمان"\n'
        'Sadaqah Jariyah for Eman Mohammed Tayee';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareDuaa,
            icon: const Icon(Icons.share, color: AppColors.primary),
            tooltip: 'Share Duaa',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(child: Icon(Icons.nightlight_round, size: 40, color: AppColors.accent)),
              const SizedBox(height: 16),
              Text(AppStrings.dedicatedName, textDirection: TextDirection.rtl, textAlign: TextAlign.center,
                style: AppTextStyles.calligraphy(fontSize: 36, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Iman Muhammad Taye', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSubtle)),
              const SizedBox(height: 24),
              // Her story
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: const Column(children: [
                  Text('رحمها الله رحمة واسعة وأسكنها فسيح جناته', textDirection: TextDirection.rtl, textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: AppColors.textPrimary, height: 1.6)),
                  SizedBox(height: 8),
                  Text('May Allah have vast mercy on her and grant her the spaciousness of His gardens.', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ]),
              ),
              const SizedBox(height: 24),
              // Suggested duaas
              _buildDuaaSection(),
              const SizedBox(height: 24),
              RewardButton(label: 'دعوتُ لها 🤲', icon: Icons.favorite, onPressed: _makeDuaa),
              const SizedBox(height: 16),
              // Counters
              _buildCounters(),
              const SizedBox(height: 8),
              const DedicationFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDuaaSection() {
    final duaas = NotificationData.duaas;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Text('ادعُ لها بهذه الأدعية', textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 16),
          ...duaas.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(d['ar']!, textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, height: 1.8, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(d['en']!, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle, fontStyle: FontStyle.italic)),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildCounters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [
          Text('$_duaaToday', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const Text('duaa today', style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
        ]),
        Container(width: 1, height: 40, color: AppColors.divider),
        Column(children: [
          Text('$_duaaTotal', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const Text('total deeds', style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
        ]),
      ]),
    );
  }
}
