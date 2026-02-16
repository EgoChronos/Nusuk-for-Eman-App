import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'quran_local_source.dart';
import 'supabase_service.dart';
import 'hive_storage.dart';

class AudioPlayerService extends BaseAudioHandler {
  final _player = AudioPlayer();
  final QuranLocalSource _quranSource;
  final SupabaseService? _supabaseService;
  final HiveStorage? _storage;
  
  String? _currentReciterId;
  String? _currentServerUrl;
  int? _currentSurahNumber;

  // Background Tracking
  Timer? _flushTimer;
  DateTime? _startTime;
  int _listenedSeconds = 0;

  AudioPlayerService(this._quranSource, [this._supabaseService, this._storage]) {
    _init();
  }

  void _init() {
    // Broadcast player state changes
    _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });
    
    // Listen for completion to auto-play next
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }

      // Track background listening time
      if (state.playing) {
        _startTracking();
      } else {
        _stopTracking();
      }
    });
  }

  void _startTracking() {
    _startTime = DateTime.now();
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => _flushStats());
  }

  void _stopTracking() {
    _trackCurrentSegment();
    _flushTimer?.cancel();
    _flushTimer = null;
    _flushStats();
  }

  void _trackCurrentSegment() {
    if (_startTime != null) {
      final seg = DateTime.now().difference(_startTime!).inSeconds;
      if (seg > 0) {
        _listenedSeconds += seg;
      }
      _startTime = DateTime.now();
    }
  }

  void _flushStats() {
    _trackCurrentSegment();
    if (_listenedSeconds > 0) {
      debugPrint('📊 [Background] Flushing $_listenedSeconds seconds');
      _storage?.addListeningSeconds(_listenedSeconds);
      _supabaseService?.incrementStats(listeningSeconds: _listenedSeconds);
      _listenedSeconds = 0;
    }
  }

  AudioPlayer get player => _player;

  Future<void> load({
    required String reciterId,
    required int surahNumber,
    required String surahName,
    String? localPath,
    required String serverUrl,
  }) async {
    _currentReciterId = reciterId;
    _currentServerUrl = serverUrl;
    _currentSurahNumber = surahNumber;

    final paddedNumber = surahNumber.toString().padLeft(3, '0');
    final audioUrl = '$serverUrl$paddedNumber.mp3';
    
    final mediaItem = MediaItem(
      id: audioUrl,
      album: reciterId,
      title: surahName,
      artist: reciterId,
      extras: {
        'surahNumber': surahNumber,
        'reciterId': reciterId,
      },
    );

    this.mediaItem.add(mediaItem);

    if (localPath != null && await File(localPath).exists()) {
      await _player.setFilePath(localPath);
    } else {
      await _player.setUrl(mediaItem.id);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    _stopTracking();
    await _player.stop();
  }

  @override
  Future<void> fastForward() async {
    final pos = _player.position + const Duration(seconds: 10);
    await _player.seek(pos);
  }

  @override
  Future<void> rewind() async {
    final pos = _player.position - const Duration(seconds: 10);
    await _player.seek(pos < Duration.zero ? Duration.zero : pos);
  }

  @override
  Future<void> skipToNext() async {
    if (_currentSurahNumber == null || _currentServerUrl == null || _currentReciterId == null) return;
    
    int nextNumber = _currentSurahNumber! + 1;
    if (nextNumber > 114) nextNumber = 1;
    
    await _transitionToSurah(nextNumber);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentSurahNumber == null || _currentServerUrl == null || _currentReciterId == null) return;
    
    int prevNumber = _currentSurahNumber! - 1;
    if (prevNumber < 1) prevNumber = 114;
    
    await _transitionToSurah(prevNumber);
  }

  Future<void> _transitionToSurah(int surahNumber) async {
    try {
      final surah = await _quranSource.loadSurah(surahNumber);
      await load(
        reciterId: _currentReciterId!,
        surahNumber: surahNumber,
        surahName: surah.nameArabic,
        serverUrl: _currentServerUrl!,
      );
      play();
    } catch (e) {
      debugPrint('Error transitioning to surah $surahNumber: $e');
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
