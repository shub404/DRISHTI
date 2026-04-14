import 'package:flutter/material.dart';
import 'package:sih/pages/admin_dashboard_page.dart';
import 'package:sih/theme/app_theme.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        if (_usernameController.text == 'admin' &&
            _passwordController.text == 'admin123') {
          // pushReplacement keeps a clean back-stack — back goes to Aadhar login, not here
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid credentials'),
              backgroundColor: AppTheme.classicCrimson,
            ),
          );
          setState(() => _isLoading = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context), // returns to Aadhar login
        ),
        title: const Text('ADMINISTRATION LOGIN'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SECURITY CHECKPOINT',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.inkyNavy)),
                  const Divider(),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('AUTHORIZATION',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(labelText: 'CREDENTIAL ID'),
                              validator: (v) => v!.isEmpty ? 'Please enter username' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'ACCESS CODE',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Please enter password' : null,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              icon: _isLoading
                                  ? const SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.admin_panel_settings_outlined),
                              label: Text(_isLoading ? 'VERIFYING...' : 'GRANT ACCESS'),
                              onPressed: _isLoading ? null : _handleSubmit,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderInk, width: 0.5),
                                color: AppTheme.paperBackground,
                              ),
                              child: Text(
                                'SYSTEM ADVISORY: Use authorized credentials only. All access attempts are logged.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.pencilGrey, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Switcher: back to Citizen login ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Not an admin? ',
                          style: TextStyle(color: AppTheme.pencilGrey, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'CITIZEN LOGIN →',
                          style: TextStyle(
                            color: AppTheme.inkyNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
