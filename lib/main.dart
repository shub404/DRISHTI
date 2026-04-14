import 'package:flutter/material.dart';
import 'package:sih/pages/aadhar_login.dart';
import 'package:sih/pages/admin_dashboard_page.dart';
import 'package:sih/pages/admin_login_page.dart';
import 'package:sih/pages/home_page.dart';
import 'package:sih/pages/report_issue_page.dart';
import 'package:sih/pages/settings_page.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRISHTI',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/aadharLogin',
      routes: {
        '/aadharLogin': (context) => const AadharLoginPage(),
      },
    );
  }
}