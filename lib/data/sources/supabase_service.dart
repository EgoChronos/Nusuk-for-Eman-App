import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'hive_storage.dart';

class SupabaseService {
  final SupabaseClient _client;
  final HiveStorage? _storage;

  SupabaseService(this._client, [this._storage]);

  // ── Global Stats Table Structure ──────────────────────
  // table: global_stats (id: uuid, listening_seconds: int8, ayahs_read: int8, dhikr_count: int8, duaa_count: int8)
  // Single aggregated row updated via RPC.

  // Stream global stats
  Stream<Map<String, dynamic>> getGlobalStats() {
    return _client
        .from('global_stats')
        .stream(primaryKey: ['id'])
        .map((event) {
          if (event.isEmpty) return <String, dynamic>{};
          return event.first;
        });
  }

  // Increment stats via RPC — queues locally on failure
  Future<void> incrementStats({
    int listeningSeconds = 0,
    int ayahsRead = 0,
    int dhikrCount = 0,
    int duaaCount = 0,
  }) async {
    debugPrint('📊 incrementStats called: seconds=$listeningSeconds, ayahs=$ayahsRead, dhikr=$dhikrCount, duaa=$duaaCount');
    try {
      final result = await _client.rpc('increment_global_stats', params: {
        'inc_seconds': listeningSeconds,
        'inc_ayahs': ayahsRead,
        'inc_dhikr': dhikrCount,
        'inc_duaa': duaaCount,
      });
      debugPrint('📊 incrementStats SUCCESS: $result');
    } catch (e) {
      debugPrint('📊 incrementStats FAILED: $e — queuing for later');
      // Queue for later sync
      await _storage?.addPendingSync(
        ayahs: ayahsRead,
        dhikr: dhikrCount,
        seconds: listeningSeconds,
        duaa: duaaCount,
      );
    }
  }

  // Flush any pending offline increments
  Future<void> flushPendingSync(HiveStorage storage) async {
    if (!storage.hasPendingSync()) return;

    final pending = storage.getPendingSync();
    try {
      await _client.rpc('increment_global_stats', params: {
        'inc_seconds': pending['seconds'] ?? 0,
        'inc_ayahs': pending['ayahs'] ?? 0,
        'inc_dhikr': pending['dhikr'] ?? 0,
        'inc_duaa': pending['duaa'] ?? 0,
      });
      await storage.clearPendingSync();
      debugPrint('Flushed pending sync: $pending');
    } catch (e) {
      debugPrint('Flush pending sync failed (will retry later): $e');
      // Keep the pending values — they'll be flushed next time
    }
  }

  // ── Versioning / Config ────────────────────────────────
  
  /// Fetches app configuration (including versions) from 'app_config' table.
  /// Used for Force Update logic.
  Future<Map<String, dynamic>?> getAppConfig(String key) async {
    try {
      final response = await _client
          .from('app_config')
          .select('value')
          .eq('key', key)
          .maybeSingle();
      
      return response?['value'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching app config: $e');
      return null;
    }
  }
}
