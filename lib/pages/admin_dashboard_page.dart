import 'package:flutter/material.dart';
import 'package:sih/pages/admin_analytics_page.dart';
import 'package:sih/pages/admin_issue_view_page.dart';
import 'package:sih/pages/aadhar_login.dart';
import 'package:sih/pages/resolved_issues_page.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/services/export_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;

  // Live counts from Supabase
  int _pendingCount = 0;
  int _completedCount = 0;
  int _inProgressCount = 0;
  int _rejectedCount = 0;
  bool _countsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final all = await supabase.from('issues').select('status');
      int pending = 0, completed = 0, inProgress = 0, rejected = 0;
      for (final row in all) {
        final s = (row['status'] ?? '').toString().toUpperCase();
        if (s == 'SUBMITTED') pending++;
        else if (s == 'COMPLETED') completed++;
        else if (s == 'IN PROGRESS') inProgress++;
        else if (s == 'REJECTED') rejected++;
      }
      if (mounted) {
        setState(() {
          _pendingCount = pending;
          _completedCount = completed;
          _inProgressCount = inProgress;
          _rejectedCount = rejected;
          _countsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _countsLoaded = true);
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AadharLoginPage()),
      (route) => false,
    );
  }

  Future<void> _handleExport(String filter, ExportAction action) async {
    try {
      final label = action == ExportAction.download ? 'Downloading' : 'Preparing';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('$label $filter report...', style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: AppTheme.inkyNavy,
          duration: const Duration(seconds: 2),
        ),
      );
      
      final result = await ExportService.exportRecords(filter, action: action);

      if (action == ExportAction.download && result != null && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('EXPORT SUCCESSFUL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            content: Text('The file has been saved to your device:\n\n$result', style: const TextStyle(fontSize: 12)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppTheme.classicCrimson,
          ),
        );
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppTheme.inkyNavy),
            child: const Row(
              children: [
                Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'EXPORT RECORD LOGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _exportCategoryItem('COMPLETED RECORDS', 'COMPLETED'),
          _exportCategoryItem('IN PROGRESS RECORDS', 'IN PROGRESS'),
          _exportCategoryItem('REJECTED RECORDS', 'REJECTED'),
          const Divider(height: 1),
          _exportCategoryItem('ALL ADDRESSED RECORDS', 'ADDRESSED'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _exportCategoryItem(String title, String filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.pencilGrey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save_alt, size: 16),
                  label: const Text('DOWNLOAD', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    Navigator.pop(context);
                    _handleExport(filter, ExportAction.download);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('SHARE', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    Navigator.pop(context);
                    _handleExport(filter, ExportAction.share);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exportOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.inkyNavy, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.borderInk),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMINISTRATION'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: _logout,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh counts',
            onPressed: () {
              setState(() => _countsLoaded = false);
              _loadCounts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCounts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('SYSTEM OVERVIEW',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.inkyNavy),
                    textAlign: TextAlign.center),
                const Divider(),
                const SizedBox(height: 8),
                Text('OFFICIAL DASHBOARD',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Administrative access for issue verification and community management.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.pencilGrey),
                ),
                const SizedBox(height: 32),

                // ── Live stats row ──
                if (_countsLoaded) ...[
                  Row(
                    children: [
                      _statChip('$_pendingCount', 'PENDING', AppTheme.inkyNavy),
                      const SizedBox(width: 8),
                      _statChip('$_completedCount', 'DONE', Colors.green.shade700),
                      const SizedBox(width: 8),
                      _statChip('$_inProgressCount', 'IN PROG.', Colors.orange.shade700),
                      const SizedBox(width: 8),
                      _statChip('$_rejectedCount', 'REJECTED', Colors.red.shade700),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.borderInk,
                      color: AppTheme.inkyNavy,
                    ),
                  ),

                // ── 2-tile row (compact layout to prevent overflow) ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _dashTile(
                        icon: Icons.pending_actions_outlined,
                        iconColor: AppTheme.inkyNavy,
                        title: 'PENDING',
                        subtitle: 'Review issues',
                        count: _countsLoaded ? _pendingCount : null,
                        countColor: AppTheme.inkyNavy,
                        buttonLabel: 'MANAGE',
                        filled: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminIssueViewPage()),
                        ).then((_) => _loadCounts()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dashTile(
                        icon: Icons.fact_check_outlined,
                        iconColor: Colors.green.shade700,
                        title: 'ADDRESSED',
                        subtitle: 'Resolved tasks',
                        count: _countsLoaded
                            ? (_completedCount + _inProgressCount + _rejectedCount)
                            : null,
                        countColor: Colors.green.shade700,
                        buttonLabel: 'VIEW',
                        filled: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ResolvedIssuesPage()),
                        ).then((_) => _loadCounts()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                
                // ── Analytics full-width tile ──
                _dashTile(
                  icon: Icons.bar_chart_outlined,
                  iconColor: Colors.deepPurple.shade700,
                  title: 'ANALYTICS',
                  subtitle: 'Category & status trends',
                  count: null, // Total is combined in the analytics page anyway
                  countColor: Colors.deepPurple.shade700,
                  buttonLabel: 'VIEW CHARTS',
                  filled: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAnalyticsPage()),
                  ).then((_) => _loadCounts()),
                ),

                const SizedBox(height: 24),
                Text('REPORT GENERATION',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.inkyNavy),
                    textAlign: TextAlign.center),
                const Divider(),
                const SizedBox(height: 8),

                _dashTile(
                  icon: Icons.file_download_outlined,
                  iconColor: AppTheme.inkyNavy,
                  title: 'LOG OF RECORDS',
                  subtitle: 'Export data to CSV format',
                  count: null,
                  countColor: AppTheme.inkyNavy,
                  buttonLabel: 'EXPORT LOGS',
                  filled: true,
                  onTap: _showExportOptions,
                ),

                const SizedBox(height: 32),
                const Divider(),
                Text(
                  'DRISHTI SECURE ADMINISTRATION PANEL',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.pencilGrey, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.7),
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _dashTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int? count,
    required Color countColor,
    required String buttonLabel,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.borderInk, width: 0.8),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            Text(title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.inkyNavy, fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            if (count != null) ...[
              const SizedBox(height: 2),
              Text(
                '$count items',
                style: TextStyle(fontSize: 10, color: countColor, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 4),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.pencilGrey, fontSize: 9),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            filled
                ? ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size.fromHeight(32),
                        shape: const RoundedRectangleBorder()),
                    child: Text(buttonLabel,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                : OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size.fromHeight(32),
                        shape: const RoundedRectangleBorder()),
                    child: Text(buttonLabel,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}