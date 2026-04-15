import 'package:flutter/material.dart';
import 'package:sih/pages/home_page.dart';
import 'package:sih/pages/report_issue_page.dart';
import 'package:sih/pages/track_issue.dart';
import 'package:sih/pages/my_community.dart';
import 'package:sih/pages/settings_page.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:sih/services/sync_service.dart';

class UserMainScreen extends StatefulWidget {
  final String? id;
  const UserMainScreen({super.key, required this.id});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    _syncService.initialize();
    // All pages are instantiated once and kept alive as user switches tabs
    _pages = [
      HomePage(id: widget.id),
      TrackIssuePage(id: widget.id),
      ReportIssuePage(id: widget.id),
      MyCommunityPage(id: widget.id),
      SettingsPage(id: widget.id),
    ];
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // IndexedStack keeps page state alive when switching tabs
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderInk, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              if (index == 0) _pages[0] = HomePage(id: widget.id, key: UniqueKey());
              if (index == 1) _pages[1] = TrackIssuePage(id: widget.id, key: UniqueKey());
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.paperBackground,
          selectedItemColor: AppTheme.inkyNavy,
          unselectedItemColor: AppTheme.pencilGrey,
          selectedLabelStyle: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 9,
            letterSpacing: 0.5,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'DASHBOARD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'MY REPORTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'REPORT',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'COMMUNITY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
