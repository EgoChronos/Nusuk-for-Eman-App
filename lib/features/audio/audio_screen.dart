import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dedication_footer.dart';
import '../../data/sources/hive_storage.dart';
import '../../data/sources/quran_local_source.dart';
import '../../data/models/surah.dart';
import '../../core/providers.dart';
import '../../data/sources/audio_download_service.dart';

/// Audio screen — reciters list + surah selection + player
class AudioScreen extends ConsumerStatefulWidget {
  final HiveStorage storage;
  final QuranLocalSource quranSource;

  const AudioScreen({
    super.key,
    required this.storage,
    required this.quranSource,
  });

  @override
  ConsumerState<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends ConsumerState<AudioScreen> {
  _Reciter? _selectedReciter;

  final List<_Reciter> _reciters = const [
    _Reciter(id: 'alafasy', name: 'مشاري راشد العفاسي', nameEn: 'Mishary Rashid Alafasy', serverUrl: 'https://server8.mp3quran.net/afs/'),
    _Reciter(id: 'sudais', name: 'عبد الرحمن السديس', nameEn: 'Abdul Rahman Al-Sudais', serverUrl: 'https://server11.mp3quran.net/sds/'),
    _Reciter(id: 'maher', name: 'ماهر المعيقلي', nameEn: 'Maher Al-Muaiqly', serverUrl: 'https://server12.mp3quran.net/maher/'),
    _Reciter(id: 'minshawi', name: 'محمد صديق المنشاوي', nameEn: 'Mohamed Siddiq El-Minshawi', serverUrl: 'https://server10.mp3quran.net/minsh/'),
    _Reciter(id: 'shuraym', name: 'سعود الشريم', nameEn: 'Saud Al-Shuraym', serverUrl: 'https://server7.mp3quran.net/shur/'),
    _Reciter(id: 'abdulsamad', name: 'عبد الباسط عبد الصمد', nameEn: 'Abdul Basit Abdul Samad', serverUrl: 'https://server7.mp3quran.net/basit/'),
    _Reciter(id: 'husary', name: 'محمود خليل الحصري (المعلم)', nameEn: 'Mahmoud Khalil Al-Husary (Moallim)', serverUrl: 'https://server13.mp3quran.net/husr/'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'استمع للقرآن',
          style: TextStyle(fontFamily: 'Amiri', fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedReciter == null
                ? _buildReciterList()
                : _SurahSelector(
                    reciterId: _selectedReciter!.id,
                    serverUrl: _selectedReciter!.serverUrl,
                    storage: widget.storage,
                    quranSource: widget.quranSource,
                    downloadService: ref.watch(audioDownloadServiceProvider),
                    onBack: () => setState(() => _selectedReciter = null),
                  ),
          ),
          const DedicationFooter(),
        ],
      ),
    );
  }

  Widget _buildReciterList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reciters.length,
      itemBuilder: (context, index) {
        final reciter = _reciters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.headphones_rounded,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              reciter.name,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              reciter.nameEn,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSubtle,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSubtle,
            ),
            onTap: () => setState(() => _selectedReciter = reciter),
          ),
        );
      },
    );
  }
}

class _SurahSelector extends StatefulWidget {
  final String reciterId;
  final String serverUrl;
  final HiveStorage storage;
  final QuranLocalSource quranSource;
  final AudioDownloadService downloadService;
  final VoidCallback onBack;

  const _SurahSelector({
    required this.reciterId,
    required this.serverUrl,
    required this.storage,
    required this.quranSource,
    required this.downloadService,
    required this.onBack,
  });

  @override
  State<_SurahSelector> createState() => _SurahSelectorState();
}

class _SurahSelectorState extends State<_SurahSelector> {
  List<Surah> _surahs = [];
  bool _isSelectionMode = false;
  final Set<int> _selectedSurahs = {};
  final Map<int, double> _downloading = {};
  StreamSubscription? _downloadSub;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    
    // Check for already active downloads from this reciter
    for (int i = 1; i <= 114; i++) {
      if (widget.downloadService.isDownloading(widget.reciterId, i)) {
        _downloading[i] = 0.0;
      }
    }

    try {
      _downloadSub = widget.downloadService.progressStream.listen((event) {
        debugPrint('UI: Received progress: ${event.reciterId}-${event.surahNumber} -> ${event.progress}');
        if (event.reciterId == widget.reciterId) {
          setState(() {
            if (event.isCompleted || event.isFailed) {
              _downloading.remove(event.surahNumber);
            } else {
              _downloading[event.surahNumber] = event.progress;
            }
          });
        }
      }, onError: (e) {
        debugPrint('UI: Progress stream error: $e');
      });
    } catch (e) {
      debugPrint('UI: Failed to listen to progress stream: $e');
    }
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    final surahs = await widget.quranSource.loadSurahs();
    if (mounted) {
      setState(() {
        _surahs = surahs;
      });
    }
  }

  Future<void> _startDownload(int surahNumber) async {
    debugPrint('UI: Starting download for surah $surahNumber');
    await widget.downloadService.downloadSurah(
      reciterId: widget.reciterId,
      surahNumber: surahNumber,
      serverUrl: widget.serverUrl,
    );
  }

  Future<void> _startBatchDownload() async {
    final toDownload = _selectedSurahs.toList();
    setState(() {
      _isSelectionMode = false;
      _selectedSurahs.clear();
    });

    for (final number in toDownload) {
      if (!widget.storage.isDownloaded(widget.reciterId, number)) {
        // We don't await here to allow concurrent-ish start or sequential background start
        // Actually our service handles them sequentially if we want, or concurrently.
        // For now, let's just trigger them.
        _startDownload(number);
      }
    }
  }

  void _selectAll() {
    setState(() {
      for (final s in _surahs) {
        if (!widget.storage.isDownloaded(widget.reciterId, s.number)) {
          _selectedSurahs.add(s.number);
        }
      }
    });
  }

  void _cancelDownload(int surahNumber) {
    widget.downloadService.cancelDownload(widget.reciterId, surahNumber);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _surahs.isEmpty
          ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              key: const ValueKey('content'),
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _surahs.length,
                    itemBuilder: (context, index) {
                      final surah = _surahs[index];
                      final isDownloaded = widget.storage.isDownloaded(widget.reciterId, surah.number);
                      final downloadProgress = _downloading[surah.number];
                      final isSelected = _selectedSurahs.contains(surah.number);

                      final isSurahYaseen = surah.number == 36;
                      return Container(
                        decoration: isSurahYaseen
                            ? BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.1), // Gold tint
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                              )
                            : null,
                        margin: isSurahYaseen ? const EdgeInsets.symmetric(vertical: 4, horizontal: 8) : null,
                        child: ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                activeColor: AppColors.primary,
                                onChanged: isDownloaded
                                    ? null
                                    : (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedSurahs.add(surah.number);
                                          } else {
                                            _selectedSurahs.remove(surah.number);
                                          }
                                        });
                                      },
                              )
                            : Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              child: isSurahYaseen
                                  ? const Icon(Icons.favorite, color: Color(0xFFD4AF37), size: 20)
                                  : Text(
                                      '${surah.number}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              ),
                        title: Text(
                          surah.nameArabic,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
                        ),
                        subtitle: isSurahYaseen
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(surah.nameEnglish),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Loved by Eman',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              )
                            : Text(surah.nameEnglish),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDownloaded)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SAVED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (downloadProgress != null)
                              Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none, // Allow button to overflow
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      value: downloadProgress,
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    '${(downloadProgress * 100).toInt()}%',
                                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  Positioned(
                                    top: -12,
                                    right: -12,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        debugPrint('UI: Tapped cancel for surah ${surah.number}');
                                        _cancelDownload(surah.number);
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else if (!_isSelectionMode)
                              IconButton(
                                icon: Icon(
                                  isDownloaded ? Icons.file_download_done : Icons.file_download_outlined,
                                  color: isDownloaded ? AppColors.accent : AppColors.textSubtle,
                                ),
                                onPressed: isDownloaded ? null : () => _startDownload(surah.number),
                              ),
                          ],
                        ),
                        onTap: _isSelectionMode
                            ? (isDownloaded
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedSurahs.remove(surah.number);
                                      } else {
                                        _selectedSurahs.add(surah.number);
                                      }
                                    });
                                  })
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AudioPlayerScreen(
                                      reciterId: widget.reciterId,
                                      serverUrl: widget.serverUrl,
                                      surahNumber: surah.number,
                                      surahNameArabic: surah.nameArabic,
                                      surahNameEnglish: surah.nameEnglish,
                                      storage: widget.storage,
                                      quranSource: widget.quranSource,
                                      downloadService: widget.downloadService,
                                    ),
                                  ),
                                );
                              },
                      ),
                    );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedSurahs.clear();
              }),
              icon: const Icon(Icons.close),
            ),
            Text(
              '${_selectedSurahs.length} Selected',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: _selectAll,
              child: const Text('Select All'),
            ),
            if (_downloading.isNotEmpty)
              IconButton(
                onPressed: () => widget.downloadService.cancelAll(),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                tooltip: 'Cancel All',
              ),
            IconButton(
              onPressed: _selectedSurahs.isEmpty ? null : _startBatchDownload,
              icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const Text(
            'Select Surah',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (_downloading.isNotEmpty)
            TextButton.icon(
              onPressed: () => widget.downloadService.cancelAll(),
              icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
              label: Text(
                'Cancel (${_downloading.length})',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          IconButton(
            onPressed: () => setState(() => _isSelectionMode = true),
            icon: const Icon(Icons.library_add_check_outlined, color: AppColors.textSecondary),
            tooltip: 'Bulk Download',
          ),
        ],
      ),
    );
  }
}

/// Audio player screen with play/pause, seek, background playback
class AudioPlayerScreen extends ConsumerStatefulWidget {
  final String reciterId;
  final String serverUrl;
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final HiveStorage storage;
  final QuranLocalSource quranSource;
  final AudioDownloadService downloadService;

  const AudioPlayerScreen({
    super.key,
    required this.reciterId,
    required this.serverUrl,
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.storage,
    required this.quranSource,
    required this.downloadService,
  });

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = true;
  bool _isBuffering = false;
  Duration _bufferedPosition = Duration.zero;
  double? _downloadProgress;
  StreamSubscription? _downloadSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _bufSub;
  StreamSubscription? _playSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _itemSub;

  // Mutable surah state
  late int _surahNumber;
  late String _surahNameArabic;
  late String _surahNameEnglish;

  @override
  void initState() {
    super.initState();
    _surahNumber = widget.surahNumber;
    _surahNameArabic = widget.surahNameArabic;
    _surahNameEnglish = widget.surahNameEnglish;
    
    // Check for already active download
    if (widget.downloadService.isDownloading(widget.reciterId, _surahNumber)) {
      _downloadProgress = 0.0;
    }

    try {
      _downloadSub = widget.downloadService.progressStream.listen((event) {
        if (event.reciterId == widget.reciterId && event.surahNumber == _surahNumber) {
          if (mounted) {
            setState(() {
              if (event.isCompleted || event.isFailed) {
                _downloadProgress = null;
              } else {
                _downloadProgress = event.progress;
              }
            });
          }
        }
      }, onError: (e) {
        debugPrint('UI: Player progress stream error: $e');
      });
    } catch (e) {
      debugPrint('UI: Failed to listen to player progress stream: $e');
    }

    final playerService = ref.read(audioPlayerServiceProvider);
    _itemSub = playerService.mediaItem.listen((item) {
      if (item != null) {
        final newSurahNumber = item.extras?['surahNumber'] as int?;
        if (mounted && newSurahNumber != null && newSurahNumber != _surahNumber) {
          _syncWithService(item);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _initAudio());
  }

  Future<void> _initAudio() async {
    try {
      if (mounted) setState(() => _loading = true);
      final playerService = ref.read(audioPlayerServiceProvider);
      
      final localPath = widget.storage.getDownloadedPath(widget.reciterId, _surahNumber);
      await playerService.load(
        reciterId: widget.reciterId,
        surahNumber: _surahNumber,
        surahName: _surahNameArabic,
        localPath: localPath,
        serverUrl: widget.serverUrl,
      );

      _posSub?.cancel();
      _posSub = playerService.player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      }, onError: (e) => debugPrint('Player position error: $e'));

      _durSub?.cancel();
      _durSub = playerService.player.durationStream.listen((dur) {
        if (dur != null && mounted) setState(() => _duration = dur);
      }, onError: (e) => debugPrint('Player duration error: $e'));

      _bufSub?.cancel();
      _bufSub = playerService.player.bufferedPositionStream.listen((buf) {
        if (mounted) setState(() => _bufferedPosition = buf);
      }, onError: (e) => debugPrint('Player buffer error: $e'));

      _playSub?.cancel();
      _playSub = playerService.player.playingStream.listen((playing) {
        if (mounted) setState(() => _isPlaying = playing);
      }, onError: (e) => debugPrint('Player playing error: $e'));

      _stateSub = playerService.player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isBuffering = state.processingState == ProcessingState.buffering || 
                           state.processingState == ProcessingState.loading;
          });
        }
      }, onError: (e) => debugPrint('Player state error: $e'));

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('UI: Audio init error: $e');
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load audio.')),
        );
      }
    }
  }

  void _playNextSurah() {
    ref.read(audioPlayerServiceProvider).skipToNext();
  }

  void _playPreviousSurah() {
    ref.read(audioPlayerServiceProvider).skipToPrevious();
  }

  Future<void> _syncWithService(MediaItem item) async {
    final surahNumber = item.extras?['surahNumber'] as int?;
    if (surahNumber != null) {
      try {
        final surahs = await widget.quranSource.loadSurahs();
        final surah = surahs.firstWhere((s) => s.number == surahNumber);
        
        if (mounted) {
          setState(() {
            _surahNumber = surahNumber;
            _surahNameArabic = surah.nameArabic;
            _surahNameEnglish = surah.nameEnglish;
            _position = Duration.zero;
            _duration = Duration.zero;
            _downloadProgress = null; 
          });
        }
      } catch (e) {
        debugPrint('UI: Sync error: $e');
      }
    }
  }

  Future<void> _startDownload() async {
    await widget.downloadService.downloadSurah(
      reciterId: widget.reciterId,
      surahNumber: _surahNumber,
      serverUrl: widget.serverUrl,
    );
  }

  Future<void> _togglePlay() async {
    final playerService = ref.read(audioPlayerServiceProvider);
    if (_isPlaying) {
      await playerService.pause();
    } else {
      await playerService.play();
    }
  }

  @override
  void dispose() {
    widget.storage.saveLastAudioPosition(
      widget.reciterId,
      _surahNumber,
      _position.inMilliseconds,
    );
    _downloadSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _bufSub?.cancel();
    _playSub?.cancel();
    _stateSub?.cancel();
    _itemSub?.cancel();
    // We explicitly DON'T dispose playerService.player here because it's global
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _surahNameArabic,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 20),
        ),
        actions: [
          if (_downloadProgress != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: _downloadProgress,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => widget.downloadService.cancelDownload(widget.reciterId, _surahNumber),
                  ),
                ],
              ),
            )
          else
            IconButton(
              icon: Icon(
                widget.storage.isDownloaded(widget.reciterId, _surahNumber)
                    ? Icons.file_download_done
                    : Icons.file_download,
                color: widget.storage.isDownloaded(widget.reciterId, _surahNumber)
                    ? AppColors.primary
                    : null,
              ),
              onPressed: widget.storage.isDownloaded(widget.reciterId, _surahNumber)
                  ? null
                  : _startDownload,
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _loading
            ? Center(
                key: const ValueKey('loading'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _surahNameArabic,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Preparing audio...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                key: const ValueKey('player'),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Album art placeholder
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.surahNumber == 36
                              ? [const Color(0xFFD4AF37), const Color(0xFFAA8C2C)] // Gold gradient
                              : [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: widget.surahNumber == 36
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: widget.surahNumber == 36
                            ? const Icon(
                                Icons.favorite_rounded,
                                size: 80,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.menu_book_rounded,
                                size: 80,
                                color: AppColors.accent,
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      _surahNameArabic,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _surahNameEnglish,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    if (_surahNumber == 36) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Loved by Eman',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFD4AF37),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Seek bar with buffer
                    SizedBox(
                      height: 30,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Buffer track
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: LinearProgressIndicator(
                              value: (_duration.inMilliseconds > 0
                                      ? _bufferedPosition.inMilliseconds /
                                          _duration.inMilliseconds
                                      : 0.0)
                                  .clamp(0.0, 1.0),
                              backgroundColor: AppColors.divider.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation(Colors.grey.withValues(alpha: 0.5)),
                              minHeight: 3,
                            ),
                          ),
                          // Interactive Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.transparent, // Transparent because we use the LinearProgressIndicator below
                              thumbColor: AppColors.primary,
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            ),
                            child: Slider(
                              value: (_duration.inMilliseconds > 0
                                      ? _position.inMilliseconds /
                                          _duration.inMilliseconds
                                      : 0.0)
                                  .clamp(0.0, 1.0),
                              onChanged: (value) {
                                ref.read(audioPlayerServiceProvider).seek(Duration(
                                  milliseconds:
                                      (value * _duration.inMilliseconds).toInt(),
                                ));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Time labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSubtle,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _playNextSurah,
                          icon: const Icon(Icons.skip_next_rounded, size: 32),
                          color: AppColors.textPrimary,
                        ),
                        IconButton(
                          onPressed: () {
                            ref.read(audioPlayerServiceProvider).seek(Duration(
                              milliseconds:
                                  (_position.inMilliseconds - 10000)
                                      .clamp(0, _duration.inMilliseconds),
                            ));
                          },
                          icon: const Icon(Icons.replay_10, size: 32),
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _togglePlay,
                            icon: _isBuffering
                                ? const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            ref.read(audioPlayerServiceProvider).seek(Duration(
                              milliseconds:
                                  (_position.inMilliseconds + 10000)
                                      .clamp(0, _duration.inMilliseconds),
                            ));
                          },
                          icon: const Icon(Icons.forward_10, size: 32),
                          color: AppColors.textPrimary,
                        ),
                        IconButton(
                          onPressed: _playPreviousSurah,
                          icon: const Icon(Icons.skip_previous_rounded, size: 32),
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    const DedicationFooter(),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}

class _Reciter {
  final String id;
  final String name;
  final String nameEn;
  final String serverUrl;

  const _Reciter({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.serverUrl,
  });
}
