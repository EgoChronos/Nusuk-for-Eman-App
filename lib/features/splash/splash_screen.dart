import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../onboarding/intention_choice_screen.dart';
import '../../app.dart'; // For MainScreen
import '../../core/providers.dart'; // For hiveStorageProvider

import 'package:hijri/hijri_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/sources/supabase_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/sources/quran_local_source.dart';
import '../../data/sources/audio_player_service.dart';
import 'package:shared_preferences/shared_preferences.dart' as sp;

/// Splash screen — emotional entry point
/// Shows her name + duaa, then navigates to home or onboarding
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    // Start initialization sequence
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // 1. Initialize Services
    await _initServices();

    // 2. Ensure minimum splash duration (e.g. 3 seconds total)
    // BYPASS if there's a pending navigation from overlay
    final prefs = await sp.SharedPreferences.getInstance();
    await prefs.reload(); // CRITICAL: See changes from other isolates
    final hasPendingNav = prefs.containsKey('pending_navigation');

    if (!hasPendingNav) {
      final elapsed = DateTime.now().difference(startTime);
      final minDuration = const Duration(seconds: 3);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    } else {
      debugPrint('SplashScreen: Pending navigation detected! Bypassing delay.');
    }

    if (!mounted) return;

    // 3. Navigate
    final storage = ref.read(hiveStorageProvider);
    final isFirst = storage.isFirstLaunch;
    
    if (isFirst) {
      _navigateWithFade(context, const IntentionChoiceScreen());
    } else {
      _navigateWithFade(context, MainScreen(storage: storage));
    }
  }

  Future<void> _initServices() async {
    final storage = ref.read(hiveStorageProvider);

    // [Moved from main.dart] Check for New Hijri Month
    try {
      final today = HijriCalendar.now();
      final lastMonth = storage.getLastHijriMonth();

      if (lastMonth == -1) {
        await storage.setLastHijriMonth(today.hMonth);
      } else if (lastMonth != today.hMonth) {
        debugPrint('New Hijri Month Detected (${today.hMonth}). Resetting progress.');
        await storage.resetReadingProgress();
        await storage.setLastHijriMonth(today.hMonth);
      }
    } catch (e) {
      debugPrint('Failed to check Hijri date: $e');
    }

    // [Moved from main.dart] Initialize Notification Service (Background)
    try {
      debugPrint('Initializing NotificationService singleton...');
      final notificationService = NotificationService();
      await notificationService.init(storage);
      
      // Request permission now that we have a UI context (Splash)
      final permissionGranted = await notificationService.requestPermission();
      debugPrint('NotificationService: Permission granted: $permissionGranted');
      
      debugPrint('NotificationService initialized successfully via Singleton');
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }

    // Initialize Supabase (Background)
    const supabaseUrl = 'https://acgypshlngciyakvjpec.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFjZ3lwc2hsbmdjaXlha3ZqcGVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwMjE3NTQsImV4cCI6MjA4NjU5Nzc1NH0.84-Kq6Tu31oNtlISH9QXo-yZx7UctZY4RhNvxWpJQ5Y';
    SupabaseService? supabaseService;
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
      supabaseService = SupabaseService(Supabase.instance.client, storage);
      supabaseService.flushPendingSync(storage);
      
      // Update the provider
      ref.read(supabaseServiceStateProvider.notifier).state = supabaseService;
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
    
    // Audio Init
     try {
      debugPrint('Initializing AudioService...');
      final quranSource = QuranLocalSource();
      final audioHandler = await AudioService.init(
        builder: () => AudioPlayerService(quranSource, supabaseService, storage),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.nusuk_for_iman.audio',
          androidNotificationChannelName: 'Nusuk Audio Playback',
          androidStopForegroundOnPause: true,
        ),
      );
      // Update provider
      ref.read(audioPlayerServiceStateProvider.notifier).state = audioHandler;
    } catch (e) {
      debugPrint('AudioService init failed: $e');
    }
  }

  void _navigateWithFade(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Use EaseInOut for smoother "breathing" transition
          var curve = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(opacity: curve, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1200), // Slower, smoother
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gold crescent icon
                Icon(
                  Icons.nightlight_round,
                  size: 64,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 32),
                // Her name
                Text(
                  AppStrings.dedicatedName,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.calligraphy(
                    fontSize: 42,
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // Duaa
                const Text(
                  AppStrings.splashDuaa,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: AppColors.accentLight,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                // Subtle loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple provider to check first launch
final isFirstLaunchProvider = Provider<bool>((ref) {
  // Will be overridden in main.dart
  return true;
});
