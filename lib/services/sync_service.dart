import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sih/services/draft_service.dart';
import 'package:sih/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = Supabase.instance.client;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_handleConnectionChange);
    // Attempt initial sync
    _attemptSync();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _handleConnectionChange(List<ConnectivityResult> results) async {
    if (!results.contains(ConnectivityResult.none)) {
      await _attemptSync();
    }
  }

  Future<void> _attemptSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final drafts = await DraftService.loadDrafts();
      // Only process auto-sync drafts
      for (int i = 0; i < drafts.length; i++) {
        final draft = drafts[i];
        if (draft.autoSync && draft.userId != null) {
          final success = await _submitDraft(draft);
          if (success) {
            // Delete the draft after successful sync
            // Note: loading drafts fresh to avoid index changes if multiple syncing is happening (though unlikely)
            final currentDrafts = await DraftService.loadDrafts();
            final indexToDelete = currentDrafts.indexWhere((d) => d.timestamp == draft.timestamp);
            if (indexToDelete != -1) {
              await DraftService.deleteDraft(indexToDelete);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _submitDraft(DraftReport draft) async {
    try {
      if (draft.imagePath == null) return false;
      final file = File(draft.imagePath!);
      if (!file.existsSync()) return false;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageBytes = await file.readAsBytes();

      // Ensure AI categorize gets called but ignore failure
      String category = 'UNCATEGORISED';
      try {
        final aiResult = await ApiService.categorizeIssue(
          image: file,
          lat: draft.lat ?? 0.0,
          lon: draft.lon ?? 0.0,
          description: draft.description,
        );
        category = _mapCategory(aiResult['category']?.toString() ?? '');
      } catch (e) {
        debugPrint('Auto-sync AI categorise failed: $e');
      }

      await _supabase.storage.from('drishti').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      final String downloadUrl = _supabase.storage.from('drishti').getPublicUrl(fileName);

      await _supabase.from('issues').insert({
        'user_id': draft.userId,
        'description': draft.description,
        'category': category,
        'latitude': draft.lat,
        'longitude': draft.lon,
        'image_url': downloadUrl,
        'status': 'SUBMITTED',
      });
      return true;
    } catch (e) {
      debugPrint('Error submitDraft in auto-sync: $e');
      return false;
    }
  }

  String _mapCategory(String pred) {
    final p = pred.toUpperCase().trim();
    const valid = [
      'ROAD', 'WATER', 'ELECTRICITY', 'SANITATION',
      'TREE', 'STRAY ANIMALS', 'NOISE', 'TRAFFIC', 'BUILDING',
      'FIRE HAZARD', 'PUBLIC HEALTH', 'CRIME', 'FLOOD DRAINAGE'
    ];
    if (valid.contains(p)) return p;
    if (p.contains('ROAD') || p.contains('POTHOLE') || p.contains('PAVEMENT')) return 'ROAD';
    if (p.contains('WATER') || p.contains('LEAK') || p.contains('PIPE')) return 'WATER';
    if (p.contains('ELECTR') || p.contains('LIGHT') || p.contains('POLE')) return 'ELECTRICITY';
    if (p.contains('SANIT') || p.contains('GARBAGE') || p.contains('WASTE') || p.contains('TRASH')) return 'SANITATION';
    if (p.contains('TREE') || p.contains('PARK') || p.contains('PED')) return 'TREE';
    if (p.contains('STRAY') || p.contains('ANIMAL') || p.contains('DOG') || p.contains('COW')) return 'STRAY ANIMALS';
    if (p.contains('NOISE') || p.contains('SOUND') || p.contains('SPEAKER')) return 'NOISE';
    if (p.contains('TRAFFIC') || p.contains('SIGNAL') || p.contains('JAM')) return 'TRAFFIC';
    if (p.contains('BUILD') || p.contains('CONSTRUCT') || p.contains('WALL')) return 'BUILDING';
    if (p.contains('FIRE') || p.contains('GAS') || p.contains('SMOKE') || p.contains('HAZARD')) return 'FIRE HAZARD';
    if (p.contains('HEALTH') || p.contains('MOSQUITO') || p.contains('DISEASE')) return 'PUBLIC HEALTH';
    if (p.contains('CRIME') || p.contains('CCTV') || p.contains('THEFT')) return 'CRIME';
    if (p.contains('DRAIN') || p.contains('FLOOD') || p.contains('WATERLOG')) return 'FLOOD DRAINAGE';
    return 'UNCATEGORISED';
  }
}
