import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ExportAction { download, share }

class ExportService {
  static final _supabase = Supabase.instance.client;

  /// Fetches records and exports them as a CSV file.
  /// [status] can be 'COMPLETED', 'IN PROGRESS', 'REJECTED', or 'ADDRESSED' (all 3).
  static Future<String?> exportRecords(String filter, {ExportAction action = ExportAction.share}) async {
    try {
      // 1. Fetch data
      var query = _supabase.from('issues').select();
      
      if (filter == 'ADDRESSED') {
        query = query.neq('status', 'SUBMITTED');
      } else {
        query = query.eq('status', filter);
      }

      final List<dynamic> rawData = await query.order('created_at', ascending: false);
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(rawData);

      if (data.isEmpty) {
        throw Exception('No records found for $filter');
      }

      // 2. Prepare CSV rows
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        'Issue ID',
        'Category',
        'Description',
        'Status',
        'Submission Date',
        'Latitude',
        'Longitude',
        'Action Date',
        'Reason/Note',
        'Authority'
      ]);

      for (var item in data) {
        final status = (item['status'] ?? '').toString();
        
        String actionDate = '';
        String note = '';
        String authority = '';

        if (status == 'COMPLETED') {
          actionDate = item['completion_date'] ?? '';
          note = item['completion_note'] ?? '';
          authority = item['completion_authority'] ?? '';
        } else if (status == 'REJECTED') {
          actionDate = item['rejection_date'] ?? '';
          note = item['rejection_note'] ?? '';
          authority = item['rejection_authority'] ?? '';
        } else if (status == 'IN PROGRESS') {
          actionDate = 'In Progress';
          note = 'Ongoing';
          authority = 'Assigned';
        }

        rows.add([
          item['id'] ?? '',
          item['category'] ?? '',
          item['description'] ?? '',
          status,
          _formatDate(item['created_at']),
          item['latitude'] ?? '',
          item['longitude'] ?? '',
          actionDate,
          note,
          authority,
        ]);
      }

      // 3. Convert to CSV string
      final String csvData = csv.encode(rows);

      // 4. Determine path based on action
      String filePath;
      final String fileName = 'DRISHTI_${filter}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

      if (action == ExportAction.download) {
        // Persistent storage
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
      } else {
        // Temporary storage
        final directory = await getTemporaryDirectory();
        filePath = '${directory.path}/$fileName';
      }

      final file = File(filePath);
      await file.writeAsString(csvData);

      // 5. Execute Action
      if (action == ExportAction.share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            subject: 'DRISHTI Export: $filter Records',
            text: 'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          ),
        );
        return null; // Share sheet handled itself
      } else {
        // Return path for UI to show success
        return filePath;
      }

    } catch (e) {
      rethrow;
    }
  }

  static String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
