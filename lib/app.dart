import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart' as sp;
import 'package:nusuk_for_iman/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'data/sources/hive_storage.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/intention_choice_screen.dart';
import 'features/home/home_screen.dart';
import 'features/quran/quran_screen.dart';
import 'features/quran/quran_reader_screen.dart';
import 'features/audio/audio_screen.dart';
import 'features/dhikr/dhikr_screen.dart';
import 'features/hadith/hadith_screen.dart';
import 'features/duaa/duaa_screen.dart';
import 'features/settings/settings_screen.dart';
import 'core/providers.dart';
import 'core/services/permission_service.dart';

/// The root widget of the application
class NusukApp extends ConsumerWidget {
  final HiveStorage storage;
  final bool isFirstLaunch;

    const NusukApp({
    super.key,
    required this.storage,
    required this.isFirstLaunch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings
    final isDark = ref.watch(themeProvider);
    final languageCode = ref.watch(localeProvider);

    return MaterialApp(
      title: AppStrings.appNameEn,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      
      // Localization
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: Locale(languageCode),

      // Routing
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const IntentionChoiceScreen(),
        '/main': (context) => MainScreen(storage: storage),
        '/duaa': (context) => DuaaScreen(storage: storage),
        '/settings': (context) => SettingsScreen(
          storage: storage,
          onThemeChanged: () {
            // Trigger rebuild for theme change
            // In a real app, use a ThemeProvider
            (context as Element).markNeedsBuild();
          },
        ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/quran/read') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => QuranReaderScreen(
              surahNumber: args['surah'],
              startAyah: args['ayah'] ?? 1,
              quranSource: ref.read(quranLocalSourceProvider),
              storage: storage,
            ),
          );
        }
        return null;
      },
    );
  }
}

/// Main screen with bottom navigation
class MainScreen extends ConsumerStatefulWidget {
  final HiveStorage storage;
  const MainScreen({super.key, required this.storage});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check on launch
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingSignals());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingSignals();
      ref.read(permissionStateProvider.notifier).refresh(silent: true);
    }
  }

  Future<void> _checkPendingSignals() async {
    try {
      final prefs = await sp.SharedPreferences.getInstance();
      
      // CRITICAL: Reload to see changes from other isolates (Overlay)
      await prefs.reload();
      
      // 1. Check for Pending Navigation
      final route = prefs.getString('pending_navigation');
      if (route != null) {
        debugPrint('MainScreen: Found pending navigation to $route');
        await prefs.remove('pending_navigation');
        
        if (!mounted) return;
        Navigator.of(context).pushNamed(route);
      }

      // 2. Check for Pending Counter Increments
      final pendingType = prefs.getString('pending_mark_read');
      if (pendingType != null) {
        debugPrint('MainScreen: Found pending counter increment for $pendingType');
        await prefs.remove('pending_mark_read');

        // Note: increment methods now auto-queue for sync
        if (pendingType == 'duaa') {
          await widget.storage.incrementDuaa();
        } else if (pendingType == 'dhikr' || pendingType == 'reminder') {
          await widget.storage.incrementTotalDhikr();
        } else if (pendingType == 'ayah') {
          await widget.storage.incrementTotalAyahLifeCount(1);
        }
      }
    } catch (e) {
      debugPrint('MainScreen: Signal processing error: $e');
    }

    // 3. Flush any pending syncs to Supabase (Global Stats)
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.flushPendingSync(widget.storage);
    } catch (e) {
      debugPrint('MainScreen: Supabase auto-sync omitted (likely offline or uninitialized)');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure screens are updated if they depend on ephemeral state (though here they are mostly stateless/stateful widgets)
    // For simpler state management, we re-create the list or just use indexed stack with direct instantiation if needed.
    // However, to keep it clean and avoid re-creating HomeScreen state unnecessarily, we keep it in initState/didUpdateWidget.
    // But passing callback dynamically is better. Let's just instantiate connected widgets directly in children.
    
    final language = ref.watch(localeProvider);
    final isArabic = language == 'ar';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            storage: widget.storage,
            onTabChange: (index) => setState(() => _currentIndex = index),
          ),
          QuranScreen(
            quranSource: ref.read(quranLocalSourceProvider),
            storage: widget.storage,
          ),
          DhikrScreen(storage: widget.storage),
          AudioScreen(
            storage: widget.storage,
            quranSource: ref.read(quranLocalSourceProvider),
          ),
          const HadithScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: isArabic ? 'Amiri' : null, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontFamily: isArabic ? 'Amiri' : null),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: isArabic ? AppStrings.navHome : AppStrings.navHomeEn,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book),
            label: isArabic ? AppStrings.navQuran : AppStrings.navQuranEn,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.spa),
            label: isArabic ? AppStrings.navDhikr : AppStrings.navDhikrEn,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.headphones),
            label: isArabic ? AppStrings.navAudio : AppStrings.navAudioEn,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.format_quote),
            label: isArabic ? AppStrings.navHadith : AppStrings.navHadithEn,
          ),
        ],
      ),
    );
  }
}
