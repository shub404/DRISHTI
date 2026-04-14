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

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Simulate network delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_usernameController.text == 'admin' &&
            _passwordController.text == 'admin123') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.push(context, MaterialPageRoute(builder: (context)=> AdminDashboardPage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid credentials'),
              backgroundColor: AppTheme.destructiveRed,
            ),
          );
        }
        if (mounted) {
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text('Back', style: TextStyle(color: Colors.white)),
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Admin Login',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(labelText: 'Username'),
                                validator: (value) =>
                                    value!.isEmpty ? 'Please enter username' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Password'),
                                validator: (value) =>
                                    value!.isEmpty ? 'Please enter password' : null,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: _isLoading
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.login),
                                label: Text(_isLoading ? 'Signing In...' : 'Sign In'),
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: Theme.of(context)
                                    .elevatedButtonTheme
                                    .style
                                    ?.copyWith(
                                      backgroundColor:
                                          MaterialStateProperty.all(AppTheme.primaryBlue),
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Demo Credentials:\nUsername: admin\nPassword: admin123',
                                  style: TextStyle(color: AppTheme.subtleTextColor, height: 1.5),
                                ),
                              )
                            ],
                          ),
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
