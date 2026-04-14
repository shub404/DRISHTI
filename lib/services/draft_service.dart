import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DraftReport {
  final String description;
  final String? imagePath;
  final double? lat;
  final double? lon;
  final DateTime timestamp;

  DraftReport({
    required this.description,
    this.imagePath,
    this.lat,
    this.lon,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'imagePath': imagePath,
    'lat': lat,
    'lon': lon,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DraftReport.fromJson(Map<String, dynamic> json) => DraftReport(
    description: json['description'],
    imagePath: json['imagePath'],
    lat: json['lat'],
    lon: json['lon'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class DraftService {
  static const String _fileName = 'issue_drafts.json';

  static Future<File> _getDraftFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<List<DraftReport>> loadDrafts() async {
    try {
      final file = await _getDraftFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((e) => DraftReport.fromJson(e)).toList();
    } catch (e) {
      print('Error loading drafts: $e');
      return [];
    }
  }

  static Future<void> saveDraft(DraftReport draft) async {
    final drafts = await loadDrafts();
    drafts.add(draft);
    
    final file = await _getDraftFile();
    await file.writeAsString(json.encode(drafts.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteDraft(int index) async {
    final drafts = await loadDrafts();
    if (index >= 0 && index < drafts.length) {
      drafts.removeAt(index);
      final file = await _getDraftFile();
      await file.writeAsString(json.encode(drafts.map((e) => e.toJson()).toList()));
    }
  }

  static Future<void> clearAllDrafts() async {
    final file = await _getDraftFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
