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

  // ── Realtime stream: all issues, filtered client-side ──────────────────────
  // NOTE: Supabase Realtime .stream() only supports a single .eq().
  // We fetch ALL and filter in the UI so any status change is instantly visible.
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
          // ── Status filter tabs ──────────────────────────────────────────
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
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Live list ──────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No data available.'));
                }

                // Filter: exclude SUBMITTED, apply status tab
                final data = snapshot.data!.where((issue) {
                  final s = (issue['status'] ?? '').toString().toUpperCase().trim();
                  final isAddressed = s.isNotEmpty && s != 'SUBMITTED';
                  final tabMatch = selectedStatus == 'ALL' || s == selectedStatus;
                  return isAddressed && tabMatch;
                }).toList();

                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu_outlined,
                            size: 56, color: AppTheme.pencilGrey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          selectedStatus == 'ALL'
                              ? 'No addressed issues yet.'
                              : 'No "$selectedStatus" issues.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppTheme.pencilGrey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppTheme.inkyNavy,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.length,
                    itemBuilder: (context, index) =>
                        _buildCard(context, data[index]),
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
    final category =
        (issue['category'] ?? 'UNCATEGORISED').toString().toUpperCase();
    final createdAt =
        DateTime.tryParse(issue['created_at'] ?? '') ?? DateTime.now();
    final latitude = issue['latitude'];
    final longitude = issue['longitude'];

    // Completion log fields
    final completionNote = issue['completion_note'] as String?;
    final completionDate = issue['completion_date'] as String?;
    final completionAuthority = issue['completion_authority'] as String?;
    final completionProofUrl = issue['completion_proof_url'] as String?;

    final border = _borderColor(status);
    final sColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: border.withOpacity(0.07),
            child: Row(
              children: [
                Icon(_statusIcon(status), size: 16, color: sColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FILE #${id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.pencilGrey,
                            letterSpacing: 0.5),
                      ),
                      Text(
                        category,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.inkyNavy),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.1),
                    border: Border.all(color: sColor, width: 1),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: sColor,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // ── Issue body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),

                // Citizen evidence image
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : Container(
                              height: 160,
                              color: AppTheme.inkyNavy.withOpacity(0.05),
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => Container(
                        height: 64,
                        color: AppTheme.inkyNavy.withOpacity(0.05),
                        child: const Center(
                            child: Icon(Icons.image_not_supported_outlined,
                                color: AppTheme.inkyNavy)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Meta row
                Row(
                  children: [
                    const Icon(Icons.tag_outlined,
                        size: 13, color: AppTheme.pencilGrey),
                    const SizedBox(width: 4),
                    Text(category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.pencilGrey)),
                    const Spacer(),
                    Text(
                      createdAt
                          .toLocal()
                          .toString()
                          .substring(0, 16),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: AppTheme.pencilGrey, fontSize: 10),
                    ),
                  ],
                ),

                if (latitude != null && longitude != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppTheme.pencilGrey),
                    const SizedBox(width: 4),
                    Text(
                      '${(latitude as double).toStringAsFixed(4)}, ${(longitude as double).toStringAsFixed(4)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.pencilGrey),
                    ),
                  ]),
                ],

                // ── Completion log (only for COMPLETED issues) ──────────
                if (status == 'COMPLETED' &&
                    (completionNote != null ||
                        completionDate != null ||
                        completionAuthority != null)) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(
                          color: Colors.green.shade300, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment_turned_in_outlined,
                                size: 14, color: Colors.green),
                            SizedBox(width: 6),
                            Text(
                              'COMPLETION LOG',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  letterSpacing: 1.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (completionNote != null) ...[
                          Text('Work Done',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold)),
                          Text(completionNote,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Colors.green.shade900)),
                          const SizedBox(height: 6),
                        ],
                        if (completionAuthority != null) ...[
                          Text('Authority',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold)),
                          Text(completionAuthority,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Colors.green.shade900)),
                          const SizedBox(height: 6),
                        ],
                        if (completionDate != null)
                          Row(children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(completionDate,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade800)),
                          ]),
                        if (completionProofUrl != null &&
                            completionProofUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Proof',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Image.network(
                              completionProofUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox
                                  .shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}