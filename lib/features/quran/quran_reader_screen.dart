import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/dedication_footer.dart';
import '../../core/providers.dart';
import '../../data/models/surah.dart';
import '../../data/sources/quran_local_source.dart';
import '../../data/sources/hive_storage.dart';
import '../reading_closure/closure_overlay.dart';
import 'package:nusuk_for_iman/l10n/app_localizations.dart';

/// Qur'an reader — Mushaf style with continuous text
class QuranReaderScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final int startAyah;
  final QuranLocalSource quranSource;
  final HiveStorage storage;

  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    required this.startAyah,
    required this.quranSource,
    required this.storage,
  });

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  Surah? _surah;
  Set<int> _readAyahs = {};
  Set<int> _bookmarkedAyahs = {};
  bool _loading = true;
  bool _intentConfirmed = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadSurah();
  }

  Future<void> _loadSurah() async {
    final surah = await widget.quranSource.loadSurah(widget.surahNumber);
    final read = widget.storage.getReadAyahs(widget.surahNumber);
    final bookmarks = widget.storage.getBookmarkedAyahs(widget.surahNumber);
    
    if (mounted) {
      setState(() {
        _surah = surah;
        _readAyahs = read;
        _bookmarkedAyahs = bookmarks;
        _loading = false;
      });
      
      // Post-frame callback to scroll if needed
      if (widget.startAyah > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah(widget.startAyah);
        });
      }
    }
  }

  void _scrollToAyah(int ayahNumber) {
    if (_surah == null) return;
    
    // 1. Calculate character index
    int targetCharIndex = 0;
    bool found = false;
    
    // We must match exactly how RichText builds the string
    // Basmala?
    if (widget.surahNumber != 1 && widget.surahNumber != 9) {
       // We rendered Basmala as a separate Text widget, so it takes some height.
       // We can approximate its height or just ignore it implies we are offset by it.
       // But RichText starts AFTER Basmala. width constraints apply to RichText.
    }
    
    for (var ayah in _surah!.ayahs) {
      if (ayah.numberInSurah == ayahNumber) {
        found = true;
        break;
      }
      // Text + " ۝ {digits} "
      // Space (1) + Mark (1) + Digits (N) + Space (1) = 3 + N
      targetCharIndex += ayah.text.length + 3 + _toArabicDigits(ayah.numberInSurah).length;
    }
    
    if (!found) return;

    // 2. Measure Text
    final textStyle = TextStyle(
      fontFamily: 'Amiri',
      fontSize: widget.storage.getFontSize(),
      height: 2.2,
    );
    
    // Reconstruct full text for measurement
    final buffer = StringBuffer();
    for (var ayah in _surah!.ayahs) {
       buffer.write(ayah.text);
       buffer.write(' \u06dd${_toArabicDigits(ayah.numberInSurah)} ');
    }
    
    final textSpan = TextSpan(text: buffer.toString(), style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
    
    // Constraint: Screen width - horizontal padding (20 + 20)
    final boxWidth = MediaQuery.of(context).size.width - 40;
    textPainter.layout(maxWidth: boxWidth);
    
    // 3. Get Offset
    final offset = textPainter.getOffsetForCaret(
      TextPosition(offset: targetCharIndex),
      Rect.zero,
    );
    
    // 4. Scroll
    // Add offset for Basmala (approx 60-80 pixels if present) + padding
    double finalScroll = offset.dy + 24; // + vertical padding
    if (widget.surahNumber != 1 && widget.surahNumber != 9) {
        finalScroll += 80; // Approximate height of Basmala widget
    }
    
    // Limit to max scroll extent
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (finalScroll > maxScroll) finalScroll = maxScroll;
    
    _scrollController.animateTo(
      finalScroll,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
    
    // Optional: Flash highlighting?
  }

  void _showAyahMenu(int ayahNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        // Re-query state to ensure freshness (though capture is fine usually)
        final isRead = _readAyahs.contains(ayahNumber);
        final isBookmarked = _bookmarkedAyahs.contains(ayahNumber);
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    l10n.ayahNumberHeader(ayahNumber),
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Mark as Read (one-way — resets each Hijri month)
                  if (!isRead)
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.textSubtle,
                      ),
                      title: Text(l10n.markAsRead),
                      onTap: () async {
                        await widget.storage.markAyahRead(widget.surahNumber, ayahNumber);
                        await widget.storage.saveLastReadPosition(widget.surahNumber, ayahNumber);
                        
                        // Sync to Supabase
                        try {
                          ref.read(supabaseServiceProvider).incrementStats(ayahsRead: 1);
                        } catch (_) {}

                        setState(() {
                          _readAyahs.add(ayahNumber);
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text('${l10n.alreadyRead} \u2713'),
                      enabled: false,
                    ),

                  // Toggle Bookmark
                  ListTile(
                    leading: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppColors.accent : AppColors.textSubtle,
                    ),
                    title: Text(isBookmarked ? l10n.removeBookmark : l10n.bookmarkAyah),
                    onTap: () async {
                      await widget.storage.toggleAyahBookmark(widget.surahNumber, ayahNumber);
                      setState(() {
                        if (isBookmarked) {
                          _bookmarkedAyahs.remove(ayahNumber);
                        } else {
                          _bookmarkedAyahs.add(ayahNumber);
                        }
                      });
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),

                  // Mark Range
                  ListTile(
                    leading: const Icon(Icons.done_all, color: AppColors.primary),
                    title: Text(l10n.readUntilHere),
                    subtitle: Text(l10n.markPreviousAsRead),
                      onTap: () async {
                        // Mark range
                        await widget.storage.markAyahRangeRead(widget.surahNumber, 1, ayahNumber);
                        
                        // Sync to Supabase - count all ayahs in range as read
                        try {
                           ref.read(supabaseServiceProvider).incrementStats(ayahsRead: ayahNumber);
                        } catch (_) {}

                        setState(() {
                          for(int i=1; i<=ayahNumber; i++) {
                            _readAyahs.add(i);
                          }
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    // Show gentle closure message
    ClosureOverlay.show(context);
    await Future.delayed(const Duration(milliseconds: 1600));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading || _surah == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _surah!.nameArabic,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 22),
          ),
          actions: [
            // Mark entire surah as read
            IconButton(
              icon: const Icon(Icons.done_all, color: AppColors.primary),
              tooltip: l10n.markSurahRead,
              onPressed: () async {
                final ayahCount = _surah!.ayahs.length;
                await widget.storage.markAyahRangeRead(
                    widget.surahNumber, 1, ayahCount);
                
                // Sync to Supabase
                try {
                  ref.read(supabaseServiceProvider).incrementStats(ayahsRead: ayahCount);
                } catch (_) {}

                setState(() {
                  for (int i = 1; i <= ayahCount; i++) {
                    _readAyahs.add(i);
                  }
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.surahMarkedRead} \u2713'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(
                widget.storage.isBookmarked(widget.surahNumber)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: AppColors.accent,
              ),
              onPressed: () async {
                await widget.storage.toggleBookmark(widget.surahNumber);
                setState(() {});
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Intent banner
            if (!_intentConfirmed)
              _IntentBanner(
                onConfirm: () {
                  setState(() => _intentConfirmed = true);
                },
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Text(
                  'تقرأ هذا لثواب إيمان محمد طايع',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.calligraphy(
                    fontSize: 20,
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),

            // Mushaf View
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // Basmala
                    if (widget.surahNumber != 1 && widget.surahNumber != 9)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 24,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    
                    // The Text
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          children: _surah!.ayahs.map((ayah) {
                            final isRead = _readAyahs.contains(ayah.numberInSurah);
                            final isBookmarked = _bookmarkedAyahs.contains(ayah.numberInSurah);
                            
                            // Visual distinction for read/bookmarked ayahs
                            Color textColor = AppColors.textPrimary;
                            Color? bgColor;
                            
                            if (isBookmarked) {
                              bgColor = AppColors.accent.withValues(alpha: 0.2);
                            } else if (isRead) {
                              textColor = const Color(0xFF2E7D32); // Muted green
                              bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.08);
                            }
                            
                            return TextSpan(
                              children: [
                                TextSpan(
                                  text: ayah.text,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: widget.storage.getFontSize(),
                                    color: textColor,
                                    height: 2.2,
                                    backgroundColor: bgColor,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showAyahMenu(ayah.numberInSurah),
                                ),
                                // Ayah Spacer/Marker
                                TextSpan(
                                  text: ' \u06dd${_toArabicDigits(ayah.numberInSurah)} ',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: widget.storage.getFontSize() * 0.8,
                                    color: isRead
                                        ? const Color(0xFF388E3C) // Green marker for read
                                        : AppColors.accent,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showAyahMenu(ayah.numberInSurah),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const DedicationFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      if (int.tryParse(digit) != null) {
        return arabicDigits[int.parse(digit)];
      }
      return digit;
    }).join('');
  }
}

/// Intent banner shown before reading
class _IntentBanner extends StatelessWidget {
  final VoidCallback onConfirm;

  const _IntentBanner({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Column(
        children: [
          const Text(
            AppStrings.intentForHer,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.intentForHerEn,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            ),
            child: const Text(
              'نعم، أنوي ذلك',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
