import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ── IP Configuration ──────────────────────────────────────────────────────
  // 10.0.2.2  = Android Emulator loopback → maps to host machine's localhost
  // 172.22.9.29 = Physical device LAN IP → update if your PC IP changes
  static const String _emulatorBase  = 'http://10.0.2.2:8000';
  static const String _physicalBase  = 'http://172.22.9.29:8000';

  /// Try emulator URL first; fall back to physical-device LAN IP.
  /// This makes the same build work on both emulator and physical phone.
  static Future<String> _resolveBase() async {
    try {
      final resp = await http
          .get(Uri.parse('$_emulatorBase/health'))
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode < 500) return _emulatorBase;
    } catch (_) {}
    return _physicalBase;
  }

  // ── Image + Location + Description → Category ────────────────────────────
  static Future<Map<String, dynamic>> categorizeIssue({
    required File image,
    required double lat,
    required double lon,
    String? description,
  }) async {
    final base = await _resolveBase();
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$base/complaint'));
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();
      if (description != null) request.fields['text_input'] = description;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Backend ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI backend unavailable: $e');
    }
  }

  // ── Multi-modal / Text → Category (used by Admin AUTO-SORT) ───────────────────
  static Future<Map<String, dynamic>> categorizeFromText({
    required String description,
    String? imageUrl,
    double lat = 0.0,
    double lon = 0.0,
  }) async {
    final base = await _resolveBase();
    try {
      final response = await http
          .post(
            Uri.parse('$base/categorize'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'text_input': description,
              'image_url': imageUrl,
              'lat': lat,
              'lon': lon
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Backend ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Categorization failed: $e');
    }
  }
}
