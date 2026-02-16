import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/dedication_footer.dart';
import '../../data/models/surah.dart';
import '../../data/sources/quran_local_source.dart';
import '../../data/sources/hive_storage.dart';
import 'package:nusuk_for_iman/l10n/app_localizations.dart';

/// Qur'an surah list screen
class QuranScreen extends ConsumerStatefulWidget {
  final QuranLocalSource quranSource;
  final HiveStorage storage;

  const QuranScreen({
    super.key,
    required this.quranSource,
    required this.storage,
  });

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  List<Surah> _surahs = [];
  List<dynamic> _searchResults = [];
  List<AyahMatch> _bookmarkedAyahsList = [];
  bool _loading = true;
  bool _isSearching = false;
  bool _showBookmarks = false;
  final _searchFocusNode = FocusNode();

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    final surahs = await widget.quranSource.loadSurahs();
    if (mounted) {
      setState(() {
        _surahs = surahs;
        _loading = false;
      });
      _refreshBookmarksList();
    }
  }

  void _refreshBookmarksList() {
    // Aggregate all ayah bookmarks
    final bookmarks = <AyahMatch>[];
    for (var surah in _surahs) {
        final surahBookmarks = widget.storage.getBookmarkedAyahs(surah.number);
        for (var ayahNum in surahBookmarks) {
            // Find ayah text - simple lookup if ayahs are sorted
            if ((ayahNum - 1) < surah.ayahs.length) {
                 bookmarks.add(AyahMatch(surah, surah.ayahs[ayahNum - 1]));
            }
        }
    }
    setState(() {
        _bookmarkedAyahsList = bookmarks;
    });
  }

  String _removeDiacritics(String text) {
    final diacritics = RegExp(r'[\u064B-\u0652\u0670\u06D6-\u06ED]');
    return text.replaceAll(diacritics, '');
  }

  void _filter(String query, AppLocalizations l10n) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final normalizedQuery = _removeDiacritics(query);
    final results = <dynamic>[];
    
    // 1. Surah Matches
    final surahMatches = _surahs.where((s) {
      final normalizedName = _removeDiacritics(s.nameArabic);
      return normalizedName.contains(normalizedQuery) ||
          s.nameEnglish.toLowerCase().contains(query.toLowerCase()) ||
          s.number.toString() == query;
    }).toList();
    
    if (surahMatches.isNotEmpty) {
      results.add(l10n.surahsTab);
      results.addAll(surahMatches);
    }
    
    // 2. Ayah Matches (limit to > 2 chars for performance)
    if (query.length > 2) {
      final ayahMatches = <AyahMatch>[];
      for (var s in _surahs) {
        for (var a in s.ayahs) {
          final normalizedText = _removeDiacritics(a.text);
          if (normalizedText.contains(normalizedQuery)) {
            ayahMatches.add(AyahMatch(s, a));
          }
        }
      }
      
      if (ayahMatches.isNotEmpty) {
        results.add(l10n.statQuran); // Using "Qur'an" as header for ayah matches
        results.addAll(ayahMatches);
      }
    }

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahBookmarks = widget.storage.getBookmarkedSurahs();
    final totalAyahs = widget.storage.getTotalAyahsRead();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // Calculate what to show
    int itemCount = 0;
    if (_isSearching) {
        itemCount = _searchResults.length;
    } else if (_showBookmarks) {
        itemCount = _bookmarkedAyahsList.length;
    } else {
        itemCount = _surahs.length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.quranTitle,
          style: AppTextStyles.calligraphy(fontSize: 24, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Khatma progress
           Visibility(
            visible: !_isSearching && !_showBookmarks,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.ayahCountLabel(totalAyahs),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
                      ),
                      Row(
                        children: [
                          Text(
                            l10n.khatmaProgress,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showNewKhatmaDialog(l10n),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.restart_alt, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    l10n.newKhatma,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalAyahs / 6236,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 13, color: AppColors.textSubtle),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.khatmaResetNote,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSubtle, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              key: const ValueKey('quran_search_field'),
              controller: _searchController,
              onChanged: (v) => _filter(v, l10n),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: l10n.searchQuranHint,
                hintTextDirection: TextDirection.rtl,
                prefixIcon: const Icon(Icons.search, color: AppColors.textSubtle),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Toggle (Surahs / Bookmarks)
          Visibility(
            visible: !_isSearching,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      text: l10n.surahsTab,
                      isSelected: !_showBookmarks,
                      onTap: () {
                        setState(() => _showBookmarks = false);
                        _refreshBookmarksList();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleButton(
                      text: l10n.bookmarksTab,
                      isSelected: _showBookmarks,
                      onTap: () {
                        setState(() => _showBookmarks = true);
                        _refreshBookmarksList();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : itemCount == 0 && _showBookmarks
                    ? Center(child: Text(l10n.noBookmarksYet, style: const TextStyle(color: AppColors.textSubtle)))
                    : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (_isSearching) {
                        final item = _searchResults[index];
                        if (item is String) { // Header
                           return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14, 
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSubtle
                              ),
                            ),
                          );
                        } else if (item is Surah) {
                          return _SurahTile(
                            surah: item,
                            isBookmarked: surahBookmarks.contains(item.number),
                            readAyahs: widget.storage.getReadAyahs(item.number).length,
                            onTap: () => _openSurah(item.number),
                            onBookmark: () async {
                                await widget.storage.toggleBookmark(item.number);
                                setState((){});
                            },
                            onMarkRead: () async {
                              await widget.storage.markAyahRangeRead(item.number, 1, item.ayahCount);
                              setState(() {});
                            },
                          );
                        } else if (item is AyahMatch) {
                          return _AyahMatchTile(
                            match: item,
                            onTap: () => _openSurah(item.surah.number, startAyah: item.ayah.numberInSurah),
                            // Search results: show bookmark state? For now just nav.
                          );
                        }
                      } else if (_showBookmarks) {
                          // Show Bookmarked Ayahs + Delete Option
                          final match = _bookmarkedAyahsList[index];
                          return _AyahMatchTile(
                              match: match,
                              onTap: () => _openSurah(match.surah.number, startAyah: match.ayah.numberInSurah),
                              onRemove: () async {
                                  await widget.storage.toggleAyahBookmark(match.surah.number, match.ayah.numberInSurah);
                                  _refreshBookmarksList(); // Refresh list to remove item
                              },
                          );
                      } else {
                        // Normal Surah List
                        final surah = _surahs[index];
                        return _SurahTile(
                          surah: surah,
                          isBookmarked: surahBookmarks.contains(surah.number),
                          readAyahs: widget.storage.getReadAyahs(surah.number).length,
                          onTap: () => _openSurah(surah.number),
                          onBookmark: () async {
                            await widget.storage.toggleBookmark(surah.number);
                            setState(() {});
                          },
                          onMarkRead: () async {
                            await widget.storage.markAyahRangeRead(surah.number, 1, surah.ayahCount);
                            setState(() {});
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
          if (!_isSearching && !_showBookmarks) const DedicationFooter(),
        ],
      ),
    );
  }

  void _openSurah(int number, {int startAyah = 1}) {
    Navigator.of(context).pushNamed(
      '/quran/read',
      arguments: {
        'surah': number,
        'ayah': startAyah,
      },
    ).then((_) => _refreshBookmarksList()); // Refresh on return
  }

  void _showNewKhatmaDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${l10n.newKhatma}?',
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
        ),
        content: Text(
          l10n.resetConfirmContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await widget.storage.resetReadingProgress();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n.newKhatma} ✓',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              l10n.reset,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
    final String text;
    final bool isSelected;
    final VoidCallback onTap;
    
    const _ToggleButton({required this.text, required this.isSelected, required this.onTap});
    
    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: onTap,
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? null : Border.all(color: AppColors.divider),
                ),
                child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSubtle,
                    ),
                ),
            ),
        );
    }
}

class AyahMatch {
  final Surah surah;
  final Ayah ayah;
  AyahMatch(this.surah, this.ayah);
}

class _AyahMatchTile extends StatelessWidget {
  final AyahMatch match;
  final VoidCallback onTap;
  final VoidCallback? onRemove; // Optional remove callback

  const _AyahMatchTile({required this.match, required this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        onTap: onTap,
        title: Text(
          match.ayah.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
        ),
        subtitle: Text(
          '${match.surah.nameEnglish} - Ayah ${match.ayah.numberInSurah}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
        ),
        leading: const Icon(Icons.search, size: 20, color: AppColors.textSubtle),
        trailing: onRemove != null 
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onRemove,
            )
            : null,
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final Surah surah;
  final bool isBookmarked;
  final int readAyahs;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final VoidCallback? onMarkRead;

  const _SurahTile({
    required this.surah,
    required this.isBookmarked,
    required this.readAyahs,
    required this.onTap,
    required this.onBookmark,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = surah.ayahCount > 0 ? readAyahs / surah.ayahCount : 0.0;
    final isComplete = surah.ayahCount > 0 && readAyahs >= surah.ayahCount;
    final isYaseen = surah.number == 36;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      elevation: isYaseen ? 4 : 1,
      shape: isYaseen 
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
            ) 
          : null,
      color: isYaseen ? const Color(0xFFFFFBE6) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMarkRead != null ? () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    surah.nameArabic,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isComplete)
                    ListTile(
                      leading: const Icon(Icons.done_all, color: AppColors.primary),
                      title: Text(l10n.markSurahRead),
                      subtitle: Text('${surah.ayahCount} ayahs'),
                      onTap: () {
                        onMarkRead!();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                          content: Text('${surah.nameEnglish} ${l10n.alreadyFullyRead.toLowerCase()} \u2713'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text('${l10n.alreadyFullyRead} \u2713'),
                      enabled: false,
                    ),

                ],
              ),
            ),
          );
        } : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Leading number
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                          : isYaseen 
                              ? const Color(0xFFFFD700).withValues(alpha: 0.2) 
                              : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isComplete
                        ? const Icon(Icons.check, color: Color(0xFF388E3C), size: 20)
                        : Text(
                            '${surah.number}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isYaseen ? const Color(0xFFB8860B) : AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                  ),
                  if (isYaseen)
                    const Positioned(
                      top: -4,
                      right: -4,
                      child: Icon(Icons.favorite, size: 12, color: Colors.red),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          surah.nameArabic,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            fontWeight: isYaseen ? FontWeight.bold : FontWeight.w600,
                            color: isComplete
                                ? const Color(0xFF2E7D32)
                                : isYaseen ? const Color(0xFFB8860B) : null,
                          ),
                        ),
                        if (isYaseen) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite, size: 10, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.lovedByEman,
                                  style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          surah.nameEnglish,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSubtle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.ayahCountLabel(surah.ayahCount),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSubtle,
                          ),
                        ),

                        if (progress > 0) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation(
                                isComplete ? const Color(0xFF4CAF50) : AppColors.accent,
                              ),
                              minHeight: 3,
                            ),
                          ),
                          if (isComplete)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle, size: 14, color: Color(0xFF388E3C)),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Bookmark
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppColors.accent : AppColors.textSubtle,
                ),
                onPressed: onBookmark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
