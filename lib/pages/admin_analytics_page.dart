import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/theme/app_theme.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final supabase = Supabase.instance.client;
  bool _loading = true;

  // Status breakdown
  Map<String, int> statusCounts = {};
  // Category breakdown
  Map<String, int> categoryCounts = {};
  // Resolution rate
  int total = 0;
  int resolved = 0;

  static const List<String> _allCategories = [
    'ROAD', 'WATER', 'ELECTRICITY', 'SANITATION',
    'TREE', 'STRAY ANIMALS', 'NOISE', 'TRAFFIC',
    'BUILDING', 'FIRE HAZARD', 'PUBLIC HEALTH', 'CRIME',
    'FLOOD DRAINAGE', 'UNCATEGORISED',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final data = await supabase.from('issues').select('status, category');

      final Map<String, int> sCounts = {};
      final Map<String, int> cCounts = {};
      int tot = 0, res = 0;

      for (final row in data) {
        final s = (row['status'] ?? 'SUBMITTED').toString().toUpperCase();
        final c = (row['category'] ?? 'UNCATEGORISED').toString().toUpperCase();
        sCounts[s] = (sCounts[s] ?? 0) + 1;
        cCounts[c] = (cCounts[c] ?? 0) + 1;
        tot++;
        if (s == 'COMPLETED') res++;
      }

      if (mounted) {
        setState(() {
          statusCounts = sCounts;
          categoryCounts = cCounts;
          total = tot;
          resolved = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const Map<String, Color> _categoryColors = {
    'ROAD':          Color(0xFF5C6BC0),
    'WATER':         Color(0xFF29B6F6),
    'ELECTRICITY':   Color(0xFFFFCA28),
    'SANITATION':    Color(0xFF26A69A),
    'TREE':          Color(0xFF66BB6A),
    'STRAY ANIMALS': Color(0xFFFF7043),
    'NOISE':         Color(0xFFAB47BC),
    'TRAFFIC':       Color(0xFFEC407A),
    'BUILDING':      Color(0xFF8D6E63),
    'FIRE HAZARD':   Color(0xFFEF5350),
    'PUBLIC HEALTH': Color(0xFF42A5F5),
    'CRIME':         Color(0xFF78909C),
    'FLOOD DRAINAGE':Color(0xFF26C6DA),
    'UNCATEGORISED': Color(0xFFBDBDBD),
  };

  @override
  Widget build(BuildContext context) {
    final resolutionPct = total == 0 ? 0.0 : (resolved / total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ANALYTICS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel('OVERVIEW'),
                    const SizedBox(height: 12),
                    _overviewRow(resolutionPct),
                    const SizedBox(height: 24),

                    _sectionLabel('STATUS BREAKDOWN'),
                    const SizedBox(height: 12),
                    _statusBreakdown(),
                    const SizedBox(height: 24),

                    _sectionLabel('ISSUES BY CATEGORY'),
                    const SizedBox(height: 12),
                    _categoryBreakdown(),
                    const SizedBox(height: 24),

                    _sectionLabel('TOP ISSUES'),
                    const SizedBox(height: 12),
                    _topCategories(),
                    const SizedBox(height: 32),

                    Text(
                      'Data reflects all ${total} reports in the system.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.pencilGrey, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Row(children: [
        Expanded(child: Divider(color: AppTheme.borderInk)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.pencilGrey,
                  letterSpacing: 1.5)),
        ),
        Expanded(child: Divider(color: AppTheme.borderInk)),
      ]);

  Widget _overviewRow(double resolutionPct) {
    return Row(children: [
      _kpiCard('$total', 'TOTAL\nISSUES', AppTheme.inkyNavy),
      const SizedBox(width: 10),
      _kpiCard('${statusCounts['COMPLETED'] ?? 0}', 'COMPLETED', Colors.green.shade700),
      const SizedBox(width: 10),
      _kpiCard('${(resolutionPct * 100).toStringAsFixed(0)}%', 'RESOLVE\nRATE', Colors.teal.shade700),
    ]);
  }

  Widget _kpiCard(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            color: color.withValues(alpha: 0.04),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ]),
        ),
      );

  Widget _statusBreakdown() {
    final statuses = [
      ('SUBMITTED', AppTheme.inkyNavy, Icons.pending_outlined),
      ('IN PROGRESS', Colors.orange.shade700, Icons.timelapse_outlined),
      ('COMPLETED', Colors.green.shade700, Icons.check_circle_outline),
      ('REJECTED', Colors.red.shade700, Icons.block_outlined),
    ];
    return Column(
      children: statuses.map((s) {
        final count = statusCounts[s.$1] ?? 0;
        final pct = total == 0 ? 0.0 : count / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(s.$3, size: 14, color: s.$2),
                const SizedBox(width: 6),
                Text(s.$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.$2)),
                const Spacer(),
                Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.$2)),
                Text('  (${(pct * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 10, color: AppTheme.pencilGrey)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: s.$2.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(s.$2),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _categoryBreakdown() {
    return Column(
      children: _allCategories.map((cat) {
        final count = categoryCounts[cat] ?? 0;
        if (count == 0) return const SizedBox.shrink();
        final pct = total == 0 ? 0.0 : count / total;
        final color = _categoryColors[cat] ?? AppTheme.pencilGrey;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 10, height: 10, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(cat,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 130,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 28,
              child: Text('$count',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _topCategories() {
    final sorted = categoryCounts.entries
        .where((e) => e.key != 'UNCATEGORISED')
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    if (top.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No categorised issues yet.', style: TextStyle(color: AppTheme.pencilGrey)),
        ),
      );
    }

    return Column(
      children: List.generate(top.length, (i) {
        final cat = top[i].key;
        final count = top[i].value;
        final color = _categoryColors[cat] ?? AppTheme.pencilGrey;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            color: color.withValues(alpha: 0.04),
          ),
          child: Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(child: Text('${i + 1}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Text('$count issues',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ]),
        );
      }),
    );
  }
}
