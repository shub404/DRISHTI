import 'package:flutter/material.dart';
import 'package:sih/pages/home_page.dart';
import 'package:sih/pages/my_community.dart';
import 'package:sih/pages/report_issue_page.dart';
import 'package:sih/pages/settings_page.dart';
import 'package:sih/pages/track_issue.dart';
import 'package:sih/theme/app_theme.dart';

class NavigationDrawerWIdget extends StatefulWidget {
  String? id;
  NavigationDrawerWIdget({super.key, required this.id});

  @override
  State<NavigationDrawerWIdget> createState() => _NavigationDrawerWIdgetState();
}

class _NavigationDrawerWIdgetState extends State<NavigationDrawerWIdget> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppTheme.paperBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.inkyNavy,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'DRISHTI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    'OFFICIAL RECORD SYSTEM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'MAIN MENU',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.inkyNavy.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ),
            buildMenuItem(
              text: 'DASHBOARD',
              icon: Icons.home_outlined,
              navigation: HomePage(id: widget.id),
            ),
            buildMenuItem(
              text: 'REPORT INCIDENT',
              icon: Icons.add_chart_outlined,
              navigation: ReportIssuePage(id: widget.id),
            ),
            buildMenuItem(
              text: 'TRACK STATUS',
              icon: Icons.assignment_outlined,
              navigation: TrackIssuePage(id: widget.id),
            ),
            buildMenuItem(
              text: 'LOCAL RECORDS',
              icon: Icons.map_outlined,
              navigation: MyCommunityPage(id: widget.id),
            ),
            const Divider(),
            buildMenuItem(
              text: 'SETTINGS',
              icon: Icons.settings_outlined,
              navigation: SettingsPage(id: widget.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuItem({
    required String text,
    required IconData icon,
    required Widget navigation,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.inkyNavy, size: 20),
      title: Text(
        text,
        style: const TextStyle(
          color: AppTheme.inkyNavy,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer first
        Navigator.push(context, MaterialPageRoute(builder: (context) => navigation));
      },
    );
  }
}