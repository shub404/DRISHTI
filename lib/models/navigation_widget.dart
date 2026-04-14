import 'package:flutter/material.dart';
import 'package:sih/pages/home_page.dart';
import 'package:sih/pages/my_community.dart';
import 'package:sih/pages/report_issue_page.dart';
import 'package:sih/pages/settings_page.dart';
import 'package:sih/pages/track_issue.dart';

class NavigationDrawerWIdget extends StatefulWidget {
  String? id;
  NavigationDrawerWIdget({super.key, required this.id});

  @override
  State<NavigationDrawerWIdget> createState() => _NavigationDrawerWIdgetState();
}

class _NavigationDrawerWIdgetState extends State<NavigationDrawerWIdget> {
  Widget buildMenuItem({
    required String text,
    required IconData icon,
    required Widget navigation,

  }) {
    const color = Colors.white;
    const hoverColor = Colors.white70;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: const TextStyle(color: color)),
      hoverColor: hoverColor,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context)=> navigation));
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1976D2),
        child: ListView(
          children: <Widget>[
             DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1565C0),
              ),
              child: Column(
                children: [
                  Text(
                    'DRISHTI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'AADHAR ID: ${widget.id}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            buildMenuItem(
              text: 'Home',
              icon: Icons.home,
              navigation: HomePage(id: widget.id),
            ),
            buildMenuItem(
              text: 'Report Issue',
              icon: Icons.report_problem,
              navigation: ReportIssuePage(id: widget.id),
            ),
            buildMenuItem(
              text: 'Track Issue',
              icon: Icons.track_changes,
              navigation: TrackIssuePage(id: widget.id),
            ),
            buildMenuItem(
              text: 'My Community',
              icon: Icons.people,
              navigation: MyCommunityPage(id: widget.id),
            ),
            buildMenuItem(
              text: 'Settings',
              icon: Icons.settings,
              navigation: SettingsPage(id: widget.id),
            ),
          ],
        ),
      ),
    );
  }
}