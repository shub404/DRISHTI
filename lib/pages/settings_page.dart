import 'package:flutter/material.dart';
import 'package:sih/models/navigation_widget.dart';
import 'package:sih/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  String? id;
  SettingsPage({super.key, required this.id});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawerWIdget(id: widget.id),
      appBar: AppBar(
         backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }
}