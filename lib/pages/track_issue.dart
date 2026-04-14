import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/theme/app_theme.dart';

class TrackIssuePage extends StatefulWidget {
  final String? id;
  TrackIssuePage({super.key, required this.id});

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
                   Icon(Icons.folder_open_outlined, size: 64, color: AppTheme.pencilGrey.withOpacity(0.5)),
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
              final issue = issues[index];
              final description = issue['description'] ?? '';
              final latitude = issue['latitude'];
              final longitude = issue['longitude'];
              final status = (issue['status'] ?? 'UNKNOWN').toString().toUpperCase();
              final imageUrl = issue['image_url'] ?? '';
              final category = (issue['category'] ?? 'UNCATEGORISED').toString().toUpperCase();

              return Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.borderInk, width: 0.8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FILE NO. #${index + 101}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.inkyNavy,
                              fontSize: 10,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.inkyNavy, width: 1),
                            ),
                            child: Text(
                              status,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppTheme.inkyNavy,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderInk, width: 0.5),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: AppTheme.inkyNavy.withOpacity(0.05),
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: AppTheme.inkyNavy.withOpacity(0.05),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_not_supported_outlined, color: AppTheme.inkyNavy.withOpacity(0.3)),
                                          const SizedBox(height: 8),
                                          Text(
                                            'OFFICIAL EVIDENCE UNAVAILABLE',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.tag_outlined, size: 14, color: AppTheme.pencilGrey),
                              const SizedBox(width: 4),
                              Text(
                                category,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.pencilGrey,
                                ),
                              ),
                              const Spacer(),
                              if (latitude != null && longitude != null)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.pencilGrey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.pencilGrey,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
