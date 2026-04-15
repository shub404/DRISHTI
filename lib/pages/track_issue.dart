import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:sih/widgets/record_card.dart';
class TrackIssuePage extends StatefulWidget {
  final String? id;
  const TrackIssuePage({super.key, required this.id});
  @override
  State<TrackIssuePage> createState() => _TrackIssuePageState();
}
class _TrackIssuePageState extends State<TrackIssuePage> {
  final supabase = Supabase.instance.client;
  @override
  Widget build(BuildContext context) {
    final issueStream = supabase
        .from('issues')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.id ?? "")
        .order('created_at', ascending: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SUBMITTED RECORDS'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: issueStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.folder_open_outlined, size: 64, color: AppTheme.pencilGrey.withValues(alpha: 0.5)),
                   const SizedBox(height: 16),
                   Text(
                    'No records found in database.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.pencilGrey),
                  ),
                ],
              ),
            );
          }
          final issues = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              return RecordCard(
                issue: issues[index],
                index: index,
              );
            },
          );
        },
      ),
    );
  }
}
