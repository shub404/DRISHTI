import 'package:flutter/material.dart';
import 'package:sih/pages/report_issue_page.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:sih/pages/track_issue.dart';
import 'package:sih/services/draft_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/widgets/record_card.dart';
class HomePage extends StatefulWidget {
  final String? id;
  const HomePage({super.key, required this.id});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  Stream<List<Map<String, dynamic>>>? _myIssuesStream;
  @override
  void initState() {
    super.initState();
    if (widget.id != null && widget.id!.isNotEmpty) {
      _myIssuesStream = supabase
          .from('issues')
          .stream(primaryKey: ['id'])
          .eq('user_id', widget.id!)
          .order('created_at', ascending: false)
          .limit(3);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DRISHTI'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'COMMUNITY REPORTING',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.inkyNavy, letterSpacing: 4.0),
              ),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Ensuring transparency and accountability in our community through collective reporting.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.pencilGrey),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('REPORT AN INCIDENT',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('SUBMIT NEW REPORT'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ReportIssuePage(id: widget.id)));
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.history_outlined),
                        label: const Text('VIEW MY REPORTS'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => TrackIssuePage(id: widget.id)));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<DraftReport>>(
                future: DraftService.loadDrafts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final drafts = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pending_actions_outlined,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'LOCAL DRAFTS (${drafts.length})',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: Colors.orange, fontSize: 11),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              await DraftService.clearAllDrafts();
                              setState(() {});
                            },
                            child: const Text('CLEAR ALL',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.orange)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...List.generate(drafts.length, (i) {
                        final d = drafts[i];
                        final isAuto = d.autoSync;
                        final highlightColor = isAuto ? Colors.indigo : Colors.orange;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportIssuePage(
                                  id: widget.id,
                                  draftToEdit: d,
                                  draftIndex: i,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: highlightColor.withValues(alpha: 0.04),
                              border: Border.all(
                                  color: highlightColor.withValues(alpha: 0.35),
                                  width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(isAuto ? Icons.cloud_sync_outlined : Icons.content_paste_search_outlined,
                                    size: 18, color: highlightColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.description.isNotEmpty
                                            ? d.description
                                            : '(No description)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            d.timestamp
                                                .toLocal()
                                                .toString()
                                                .substring(0, 16),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.pencilGrey),
                                          ),
                                          if (isAuto) ...[
                                            const SizedBox(width: 6),
                                            Text('• Pending Sync', style: TextStyle(fontSize: 10, color: highlightColor, fontWeight: FontWeight.bold)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_outlined,
                                    size: 18, color: AppTheme.pencilGrey),
                                GestureDetector(
                                  onTap: () async {
                                    await DraftService.deleteDraft(i);
                                    setState(() {});
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Icon(Icons.delete_outline,
                                        size: 18, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
              if (_myIssuesStream != null) ...[
                Text('MY RECENT REPORTS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.inkyNavy, letterSpacing: 2.0)),
                const SizedBox(height: 8),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _myIssuesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderInk),
                        ),
                        child: Text('No reports submitted yet.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.pencilGrey),
                            textAlign: TextAlign.center),
                      );
                    }
                    return Column(
                      children: snapshot.data!.map((issue) {
                        return RecordCard(issue: issue, compact: true);
                      }).toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              Text('OFFICIAL RECORD SYSTEM',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.pencilGrey, letterSpacing: 1.0)),
            ],
          ),
        ),
      ),
    );
  }
}