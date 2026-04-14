import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:sih/pages/admin_login_page.dart';
import 'package:sih/pages/user_main_screen.dart';
import 'package:sih/pages/user_register_page.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AadharLoginPage extends StatefulWidget {
  const AadharLoginPage({super.key});

  @override
  State<AadharLoginPage> createState() => _AadharLoginPageState();
}

class _AadharLoginPageState extends State<AadharLoginPage> {
  final _aadharController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePin = true;

  final supabase = Supabase.instance.client;

  static const String _verifyFaceEndpoint = "https://pasteshub-navikarana-backend.hf.space/login-face";

  Future<void> _loginWithFace() async {
    final aadharNumber = _aadharController.text.trim();
    if (aadharNumber.isEmpty || aadharNumber.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 12-digit Aadhar number first.'), backgroundColor: AppTheme.classicCrimson),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check if user actually exists in our Supabase first
      final existingUser = await supabase.from('profiles').select().eq('id', aadharNumber).maybeSingle();
      if (existingUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aadhar not found. Please register first.'), backgroundColor: AppTheme.classicCrimson),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Open camera to verify face
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 90,
      );

      if (photo == null) {
        setState(() => _isLoading = false);
        return; // User cancelled camera
      }

      // 3. Send to API
      final request = http.MultipartRequest('POST', Uri.parse(_verifyFaceEndpoint));
      request.fields['username'] = aadharNumber;
      request.files.add(await http.MultipartFile.fromPath('image', photo.path));
      
      final streamedResponse = await request.send();
      final body = await streamedResponse.stream.bytesToString();
      
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      
      if (decoded['verified'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric Verified! Access Granted.'), backgroundColor: Colors.green));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserMainScreen(id: aadharNumber)));
        }
      } else {
        final error = decoded['error'] as String? ?? 'Face not recognized or spoof detected.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: $error'), backgroundColor: AppTheme.classicCrimson));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric service error: $e'), backgroundColor: AppTheme.classicCrimson));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final aadharNumber = _aadharController.text.trim();
        final pin = _pinController.text.trim();

        // Check citizen profile in Supabase & verify PIN
        final response = await supabase
            .from('profiles')
            .select()
            .eq('id', aadharNumber)
            .maybeSingle();

        if (response == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aadhar not found. Please register first.'),
                backgroundColor: AppTheme.classicCrimson,
              ),
            );
          }
        } else {
          // Check PIN
          final dbPin = response['pin']?.toString();
          if (dbPin != pin) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid PIN.'),
                  backgroundColor: AppTheme.classicCrimson,
                ),
              );
            }
          } else {
            // Success
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Access Granted.'),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => UserMainScreen(id: aadharNumber),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.classicCrimson,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _aadharController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CITIZEN LOGIN'),
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
                              controller: _aadharController,
                              keyboardType: TextInputType.number,
                              maxLength: 12,
                              decoration: const InputDecoration(
                                labelText: 'AADHAR NUMBER',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter Aadhar number';
                                if (v.length != 12) return 'Aadhar must be exactly 12 digits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              obscureText: _obscurePin,
                              decoration: InputDecoration(
                                labelText: '6-DIGIT PIN',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter PIN';
                                if (v.length != 6) return 'PIN must be exactly 6 digits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              icon: _isLoading
                                  ? const SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.verified_user_outlined),
                              label: Text(_isLoading ? 'VERIFYING...' : 'GRANT ACCESS (WITH PIN)'),
                              onPressed: _isLoading ? null : _handleSubmit,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.face_unlock_outlined),
                              label: const Text('BIOMETRIC SCAN (FACE ID)'),
                              onPressed: _isLoading ? null : _loginWithFace,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderInk, width: 0.5),
                                color: AppTheme.paperBackground,
                              ),
                              child: Text(
                                'SYSTEM ADVISORY: Providing false government identification is a punishable offense.',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Not registered? ', style: TextStyle(color: AppTheme.pencilGrey, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserRegisterPage())),
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'CREATE RECORD',
                                style: TextStyle(decoration: TextDecoration.underline),
                              ),
                              TextSpan(
                                text: ' →',
                                style: TextStyle(decoration: TextDecoration.none),
                              ),
                            ],
                            style: TextStyle(color: AppTheme.inkyNavy, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    child: const Text("ADMINISTRATION ACCESS →", style: TextStyle(color: AppTheme.classicCrimson, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginPage()));
                    },
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