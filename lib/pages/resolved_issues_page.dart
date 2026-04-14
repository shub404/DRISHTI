import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sih/theme/app_theme.dart';

class ResolvedIssuesPage extends StatefulWidget {
  const ResolvedIssuesPage({super.key});

  @override
  State<ResolvedIssuesPage> createState() => _ResolvedIssuesPageState();
}

class _ResolvedIssuesPageState extends State<ResolvedIssuesPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<String> categories = ['uncategorised', 'road', 'water', 'electricity', 'sanitation'];
  String selectedCategory = 'uncategorised';


  @override
  Widget build(BuildContext context) {
    final issuesRef = firestore.collection('admin').doc('resolvedIssues').collection(selectedCategory).orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('Resolved Issues'),

      ),
      body: Column(
        children: [
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index){
              final category = categories[index];
              final isSelected = category== selectedCategory;

              return GestureDetector(
                  onTap: () => setState(() => selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
            })
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: issuesRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No Resolved issues in this category.'));
                }

                final issues = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    final issue = issues[index].data() as Map<String, dynamic>;
                    final description = issue['description'] ?? '';
                    final status = issue['status'] ?? 'UNKNOWN';
                    final imageUrl = issue['image_url'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            if (imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            const SizedBox(height: 8),
                            Text('STATUS: $status'),
                            const SizedBox(height: 4),
                            Text('CATEGORY: ${issue['category'] ?? 'uncategorised'}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}