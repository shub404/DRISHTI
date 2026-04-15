import 'package:flutter/material.dart';
import 'package:sih/pages/aadhar_login.dart';
import 'package:sih/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  final String? id;
  const SettingsPage({super.key, required this.id});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // --- Account Info ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.inkyNavy.withValues(alpha: 0.05),
              border: Border.all(color: AppTheme.borderInk, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppTheme.inkyNavy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CITIZEN ID',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.pencilGrey,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        widget.id ?? 'Guest',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'ACCOUNT',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppTheme.inkyNavy),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.person_outlined,
              color: AppTheme.inkyNavy,
              size: 20,
            ),
            title: Text(
              'PROFILE DETAILS',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 15),
            ),
            subtitle: Text(
              'Manage your official information',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.pencilGrey,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.inkyNavy,
              size: 20,
            ),
            title: Text(
              'NOTIFICATIONS',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 15),
            ),
            subtitle: Text(
              'Configure status alerts',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.pencilGrey,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'SYSTEM',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppTheme.inkyNavy),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.lock_outlined,
              color: AppTheme.inkyNavy,
              size: 20,
            ),
            title: Text(
              'DATA PRIVACY',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 15),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.pencilGrey,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const AadharLoginPage(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: AppTheme.classicCrimson),
            label: const Text(
              'LOG OUT',
              style: TextStyle(color: AppTheme.classicCrimson),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.classicCrimson),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          Text(
            'DRISHTI v1.0 - OFFICIAL RECORD SYSTEM',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.pencilGrey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
