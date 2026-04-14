import 'package:flutter/material.dart';
import 'package:sih/models/navigation_widget.dart';
import 'package:sih/pages/report_issue_page.dart';
import 'package:sih/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  String? id;

   HomePage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawerWIdget(id: id,),
      appBar: AppBar(
        
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'DRISHTI',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Report issues and track their resolution',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 48),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.description),
                              label: const Text('Report Issue'),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ReportIssuePage(id: id)));
                              },
                              style: Theme.of(context)
                                  .elevatedButtonTheme
                                  .style
                                  ?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all(AppTheme.primaryBlue),
                                  ),
                            ),
                            
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}