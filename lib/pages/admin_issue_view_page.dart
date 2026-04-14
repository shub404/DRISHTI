  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:sih/theme/app_theme.dart';

  class AdminIssueViewPage extends StatefulWidget {
    const AdminIssueViewPage({super.key});

    @override
    State<AdminIssueViewPage> createState() => _AdminIssueViewPageState();
  }

  class _AdminIssueViewPageState extends State<AdminIssueViewPage> {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final List<String> categories = ['uncategorised', 'road', 'water', 'electricity', 'sanitation'];
    String selectedCategory = 'uncategorised';

    // Categorize all uncategorized issues based on 'category' field
    Future<void> categorizeAllIssues() async {
    final uncategorizedRef = firestore.collection('admin').doc('issues').collection('uncategorised');
    final snapshot = await uncategorizedRef.get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = (data['category'] ?? 'uncategorised').toString().toLowerCase();

      // Ensure the category exists in your category list
      final targetCategory = categories.contains(category) ? category : 'uncategorised';
      final targetRef = firestore.collection('admin').doc('issues').collection(targetCategory);

      // Copy to target category
      await targetRef.doc(doc.id).set(data);

      // Delete only if the category is NOT uncategorised
      if (targetCategory != 'uncategorised') {
        await doc.reference.delete();
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All issues categorized successfully!')),
    );

    setState(() {
      selectedCategory = 'uncategorised'; // refresh view
    });
  }


    @override
    Widget build(BuildContext context) {
      final issuesRef = firestore
          .collection('admin')
          .doc('issues')
          .collection(selectedCategory)
          .orderBy('timestamp', descending: true);

      final resolvedIssuesRef = firestore.collection('admin').doc('resolvedIssues').collection(selectedCategory);

      final userIssue = firestore.collection('users');

      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBlue,
          title: const Text('Manage Issues'),
          actions: [
            TextButton(
              onPressed: categorizeAllIssues,
              
              child: const Text(
                'Categorize All',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Horizontal category selector
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;
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
                },
              ),
            ),

            // Display issues
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: issuesRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No issues in this category.'));
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
    final status = issue['status'] ?? 'IN PROGRESS';
    final imageUrl = issue['image_url']; // assuming you store image in Firestore
    final userID = issue['userID'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          description,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text("STATUS: $status"),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          if (latitude != null && longitude != null)
            Text("Location: ($latitude, $longitude)",
                style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Text("Submitted at: ${issue['timestamp']?.toDate()}"),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 100,
                height: 80,
                child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final issueData = issue.data() as Map<String, dynamic>; // Get all issue fields

                        // Add to resolvedIssues collection
                        await resolvedIssuesRef.doc(issue.id).set({
                          ...issueData,
                          'status': 'COMPLETED', // Ensure status is updated
                          'resolvedAt': FieldValue.serverTimestamp(),
                        });
                        
                        await userIssue.doc(userID).collection('submittedIssues').doc(description).set({
                          'status': 'COMPLETED', // Ensure status is updated
                          'resolvedAt': FieldValue.serverTimestamp(),
                        },
                        SetOptions(merge: true));

                        // Delete from the original category collection
                        final category = issueData['category'] ?? 'uncategorised';
                        try {
  await firestore
      .collection('admin')
      .doc('issues')
      .collection('uncategorised')
      .doc(description)
      .delete();

  print("Deleted: /admin/issues/uncategorised/$description");
} catch (e) {
  print("Delete failed: $e");
}
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 1),
                            content: Text("Issue marked as COMPLETED"),
                            backgroundColor: Colors.green,
                          ),
                        );

                        setState(() {}); // Refresh the UI to remove the issue from the list
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },


                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Mark as \nCompleted", style: TextStyle(fontSize: 10),),
                ),
              ),
              Container(
                width: 100,
                child: ElevatedButton(
                  onPressed: () async {
                    await issue.reference.update({'status': 'IN PROGRESS'});
                    await userIssue.doc(userID).collection('submittedIssues').doc(description).set({
                      'status': 'IN PROGRESS', // Ensure status is updated
                      'resolvedAt': FieldValue.serverTimestamp(),
                    },
                    SetOptions(merge: true));

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(seconds: 1),
                        content: Text("SET Status as IN-PROGRESS"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Set: \nIN PROGRESS", style: TextStyle(fontSize: 10), textAlign: TextAlign.center,),
                ),
              ),
              Container(
                width: 100,
                child: ElevatedButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(seconds: 1),
                        content: Text("Issue sent to respective Ministry"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Send to \nRespective Ministry", style: TextStyle(fontSize: 10), textAlign: TextAlign.center,),
                ),
              ),
            ],
          ),
        ],
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
