import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'hive_storage.dart';

class DownloadProgress {
  final String reciterId;
  final int surahNumber;
  final double progress;
  final bool isCompleted;
  final bool isFailed;

  DownloadProgress({
    required this.reciterId,
    required this.surahNumber,
    required this.progress,
    this.isCompleted = false,
    this.isFailed = false,
  });
}

class AudioDownloadService {
  final HiveStorage storage;
  final Map<String, http.Client> _activeClients = {};
  final StreamController<DownloadProgress> _progressController = StreamController<DownloadProgress>.broadcast();

  AudioDownloadService(this.storage);

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  String _getKey(String reciterId, int surahNumber) => '$reciterId-$surahNumber';

  Future<bool> downloadSurah({
    required String reciterId,
    required int surahNumber,
    required String serverUrl,
  }) async {
    final key = _getKey(reciterId, surahNumber);
    debugPrint('Service: Attempting download for $key');
    if (_activeClients.containsKey(key)) {
      debugPrint('Service: Already downloading $key');
      return false;
    }

    try {
      final client = http.Client();
      _activeClients[key] = client;

      // Emit initial zero progress so UI knows it's starting
      _progressController.add(DownloadProgress(
        reciterId: reciterId,
        surahNumber: surahNumber,
        progress: 0.0,
      ));

      final paddedNumber = surahNumber.toString().padLeft(3, '0');
      final url = '$serverUrl$paddedNumber.mp3';
      debugPrint('Service: GET $url');
      
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      final contentLength = response.contentLength ?? 0;
      debugPrint('Service: Status ${response.statusCode}, Length $contentLength');
      
      if (response.statusCode != 200) {
        debugPrint('Service: Failed with status ${response.statusCode}');
        _cleanup(key);
        return false;
      }

      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio/$reciterId');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final filePath = '${audioDir.path}/$surahNumber.mp3';
      debugPrint('Service: Saving to $filePath');
      final file = File(filePath);
      final sink = file.openWrite();
      
      int downloaded = 0;

      try {
        await for (var chunk in response.stream) {
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            final progress = downloaded / contentLength;
            debugPrint('Download progress ($reciterId-$surahNumber): $progress');
            _progressController.add(DownloadProgress(
              reciterId: reciterId,
              surahNumber: surahNumber,
              progress: progress,
            ));
          }
        }
        await sink.close();
      } catch (e) {
        await sink.close();
        if (await file.exists()) await file.delete();
        rethrow;
      }

      await storage.saveDownloadPath(reciterId, surahNumber, filePath);
      _progressController.add(DownloadProgress(
        reciterId: reciterId,
        surahNumber: surahNumber,
        progress: 1.0,
        isCompleted: true,
      ));
      
      _cleanup(key);
      return true;
    } catch (e) {
      debugPrint('Download error ($key): $e');
      _progressController.add(DownloadProgress(
        reciterId: reciterId,
        surahNumber: surahNumber,
        progress: 0.0,
        isFailed: true,
      ));
      _cleanup(key);
      return false;
    }
  }

  void cancelDownload(String reciterId, int surahNumber) {
    final key = _getKey(reciterId, surahNumber);
    _activeClients[key]?.close(); // Close connection
    _cleanup(key); // Remove from active set
    
    // Notify listeners so UI updates
    _progressController.add(DownloadProgress(
      reciterId: reciterId,
      surahNumber: surahNumber,
      progress: 0.0,
      isFailed: true, // Treat cancellation as failure/stop to reset UI
    ));
  }

  void cancelAll() {
    for (var client in _activeClients.values) {
      client.close();
    }
    _activeClients.clear();
  }

  bool isDownloading(String reciterId, int surahNumber) {
    return _activeClients.containsKey(_getKey(reciterId, surahNumber));
  }

  void _cleanup(String key) {
    _activeClients.remove(key);
  }

  Future<void> deleteDownload(String reciterId, int surahNumber) async {
    final path = storage.getDownloadedPath(reciterId, surahNumber);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await storage.removeDownload(reciterId, surahNumber);
    }
  }
}
