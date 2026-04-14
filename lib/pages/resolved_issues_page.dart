import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/theme/app_theme.dart';

/// Shows all issues that have been addressed (anything that is NOT "SUBMITTED")
class ResolvedIssuesPage extends StatefulWidget {
  const ResolvedIssuesPage({super.key});

  @override
  State<ResolvedIssuesPage> createState() => _ResolvedIssuesPageState();
}

class _ResolvedIssuesPageState extends State<ResolvedIssuesPage> {
  final supabase = Supabase.instance.client;

  final List<String> statusFilters = ['ALL', 'COMPLETED', 'IN PROGRESS', 'REJECTED'];
  String selectedStatus = 'ALL';

  late final Stream<List<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = supabase
        .from('issues')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPLETION LOG DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _showCompletionDialog(String issueId) async {
    final noteCtrl = TextEditingController();
    final authorityCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: AppTheme.inkyNavy),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'COMPLETION LOG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('WORK DONE / RESOLUTION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Describe how the issue was resolved...',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('AUTHORITY / OFFICIAL',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: authorityCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Field Engineer Name',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('DATE OF COMPLETION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: AppTheme.borderInk)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.inkyNavy),
                            const SizedBox(width: 8),
                            Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.pencilGrey, fontSize: 11)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.inkyNavy,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: isSaving ? null : () async {
                    if (noteCtrl.text.trim().isEmpty) return;
                    setDialogState(() => isSaving = true);
                    try {
                      await supabase.from('issues').update({
                        'status': 'COMPLETED',
                        'completion_note': noteCtrl.text.trim(),
                        'completion_date': '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        'completion_authority': authorityCtrl.text.trim(),
                      }).eq('id', issueId);
                      if (mounted) Navigator.pop(dialogCtx);
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                    }
                  },
                  child: Text(isSaving ? 'SAVING...' : 'COMPLETE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REJECTION LOG DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _showRejectDialog(String issueId) async {
    final reasonCtrl = TextEditingController();
    final authorityCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade800),
                child: const Row(
                  children: [
                    Icon(Icons.block_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'REJECTION LOG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('REASON FOR REJECTION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Describe why this issue is being rejected...',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('REJECTED BY (AUTHORITY)',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: authorityCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Dept Head Name',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.pencilGrey, fontSize: 11)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: isSaving ? null : () async {
                    if (reasonCtrl.text.trim().isEmpty) return;
                    setDialogState(() => isSaving = true);
                    try {
                      await supabase.from('issues').update({
                        'status': 'REJECTED',
                        'rejection_note': reasonCtrl.text.trim(),
                        'rejection_authority': authorityCtrl.text.trim(),
                        'rejection_date': '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      }).eq('id', issueId);
                      if (mounted) Navigator.pop(dialogCtx);
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                    }
                  },
                  child: Text(isSaving ? 'SAVING...' : 'REJECT', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':   return Colors.green.shade700;
      case 'IN PROGRESS': return Colors.orange.shade700;
      case 'REJECTED':    return Colors.red.shade700;
      default:            return AppTheme.inkyNavy;
    }
  }

  Color _borderColor(String status) {
    switch (status) {
      case 'COMPLETED':   return Colors.green.shade500;
      case 'IN PROGRESS': return Colors.orange.shade500;
      case 'REJECTED':    return Colors.red.shade500;
      default:            return AppTheme.borderInk;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'COMPLETED':   return Icons.check_circle_outline;
      case 'IN PROGRESS': return Icons.timelapse_outlined;
      case 'REJECTED':    return Icons.block_outlined;
      default:            return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADDRESSED'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: _refreshData,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderInk, width: 0.8)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: statusFilters.length,
              itemBuilder: (context, index) {
                final f = statusFilters[index];
                final isSelected = f == selectedStatus;
                final tabColor = f == 'ALL' ? AppTheme.inkyNavy : _statusColor(f);
                return GestureDetector(
                  onTap: () => setState(() => selectedStatus = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? tabColor : Colors.transparent,
                      border: Border.all(color: tabColor, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: isSelected ? Colors.white : tabColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) return const Center(child: Text('No data'));

                final data = snapshot.data!.where((issue) {
                  final s = (issue['status'] ?? '').toString().toUpperCase().trim();
                  return s != 'SUBMITTED' && (selectedStatus == 'ALL' || s == selectedStatus);
                }).toList();

                if (data.isEmpty) return const Center(child: Text('No matching issues.'));

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.length,
                    itemBuilder: (context, index) => _buildCard(context, data[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> issue) {
    final id = issue['id'].toString();
    final description = issue['description'] ?? '';
    final status = (issue['status'] ?? '').toString().toUpperCase().trim();
    final imageUrl = issue['image_url'] ?? '';
    final category = (issue['category'] ?? 'UNCATEGORISED').toString().toUpperCase();
    final createdAt = DateTime.tryParse(issue['created_at'] ?? '') ?? DateTime.now();

    final completionLog = {
      'note': issue['completion_note'] as String?,
      'date': issue['completion_date'] as String?,
      'authority': issue['completion_authority'] as String?,
    };

    final rejectionLog = {
      'note': issue['rejection_note'] as String?,
      'date': issue['rejection_date'] as String?,
    };

    final borderColor = _borderColor(status);
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(border: Border.all(color: borderColor, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: borderColor.withOpacity(0.05),
            child: Row(
              children: [
                Icon(_statusIcon(status), size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                ],
                const SizedBox(height: 12),
                Text(createdAt.toLocal().toString().substring(0, 16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                
                if (status == 'COMPLETED' && completionLog['note'] != null) ...[
                  const Divider(),
                  _logBox('COMPLETION LOG', completionLog['note']!, completionLog['date'], Colors.green),
                ],
                if (status == 'REJECTED' && rejectionLog['note'] != null) ...[
                  const Divider(),
                  _logBox('REJECTION LOG', rejectionLog['note']!, rejectionLog['date'], Colors.red),
                ],
                if (status == 'IN PROGRESS') ...[
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: () => _showCompletionDialog(id),
                          child: const Text('COMPLETE', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRejectDialog(id),
                          child: const Text('REJECT', style: TextStyle(fontSize: 10, color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logBox(String title, String note, String? date, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: color.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(height: 4),
          Text(note, style: const TextStyle(fontSize: 12)),
          if (date != null) Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}