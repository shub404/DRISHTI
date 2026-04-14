import 'package:flutter/material.dart';
import 'package:sih/models/navigation_widget.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackIssuePage extends StatefulWidget {
  final String? id;
  TrackIssuePage({super.key, required this.id});

  @override
  State<TrackIssuePage> createState() => _TrackIssuePageState();
}

class _TrackIssuePageState extends State<TrackIssuePage> {
  @override
  Widget build(BuildContext context) {
    CollectionReference submittedIssues = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.id)
        .collection('submittedIssues');

    Color issueColor(String progress) {
      if (progress == "COMPLETED") {
        return Colors.green.shade100;
      } else if (progress == "ONGOING" || progress == "IN PROGRESS") {
        return Colors.yellow.shade100;
      }
      return Colors.red.shade100;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submitted Issues'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            submittedIssues.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No issues submitted yet.'));
          }

          final issues = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              final description = issue['description'] ?? '';
              final latitude = issue['latitude'];
              final longitude = issue['longitude'];
              final status = issue['status'] ?? 'UNKNOWN';
              final imageUrl = issue['image_url'] ?? '';
              final category = issue['category'] ?? '';

              return Card(
                color: issueColor(status),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 180,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text("Image failed to load"),
                          ),
                        ),

                      const SizedBox(height: 12),

                      
                      Text(
                        'STATUS: $status',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'CATEGORY: $category',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ✅ Location
                      if (latitude != null && longitude != null)
                        Text(
                          'Location: ($latitude, $longitude)',
                          style: const TextStyle(color: Colors.black54),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
