import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sih/models/issue.dart';
import 'package:sih/pages/admin_issue_view_page.dart';
import 'package:sih/pages/admin_login_page.dart';
import 'package:sih/pages/resolved_issues_page.dart';
import 'package:sih/theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildHeader(context),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('Back to Home', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
            style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
          ),
          TextButton(
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> AdminLoginPage()), (route)=> false),
             style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                side: BorderSide(color: Colors.white.withOpacity(0.2))
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Text('Admin Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Manage and review reported issues',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
          ),

          const SizedBox(height: 200),
          Container(
            height: 300,
            width: 300,
            child: Column(
              children: [
                Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.description),
                                    label: const Text('MANAGE ISSUES'),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=> AdminIssueViewPage()));
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
                          SizedBox(height: 20,),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.description),
                                    label: const Text('RESOLVED ISSUES'),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=> ResolvedIssuesPage()));
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
          )
        ],
      ),
    );
  }

}