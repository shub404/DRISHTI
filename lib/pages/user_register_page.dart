import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/pages/user_main_screen.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _nameController = TextEditingController();
  final _aadharController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _captchaController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isEmulatorBypass = false;

  File? _localPhoto;
  String _captchaText = '';
  final supabase = Supabase.instance.client;

  static const String _registerFaceEndpoint = "https://shubpaste404-drishti.hf.space/register-face";

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  Future<void> _pickPhoto() async {
    final XFile? photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 90,
    );
    if (photo != null) {
      setState(() => _localPhoto = File(photo.path));
    }
  }

  Future<String?> _registerFaceOnBackend(String aadharNumber) async {
    if (_localPhoto == null) return "No photo selected.";
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_registerFaceEndpoint));
      request.fields['username'] = aadharNumber;
      request.files.add(await http.MultipartFile.fromPath('image', _localPhoto!.path));
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode == 200) return null; // Success verification

      try {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return decoded['error'] as String? ?? "Face registration failed.";
      } catch (_) {
        return "Face registration failed (status ${streamedResponse.statusCode}).";
      }
    } catch (e) {
      return "Could not reach the server. Please check your connection.";
    }
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // removed confusing I,O,0,1
    final rnd = Random();
    setState(() {
      _captchaText = String.fromCharCodes(Iterable.generate(
          5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      _captchaController.clear();
    });
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_captchaController.text.trim().toUpperCase() != _captchaText) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Captcha. Please try again.'), backgroundColor: AppTheme.classicCrimson),
        );
        _generateCaptcha();
        return;
      }

      if (!_isEmulatorBypass && _localPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture a face photo for Biometric Security'), backgroundColor: AppTheme.classicCrimson),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final aadharNumber = _aadharController.text.trim();
        final name = _nameController.text.trim();
        final pin = _pinController.text.trim();

        // Check if Aadhar already exists
        final existing = await supabase
            .from('profiles')
            .select()
            .eq('id', aadharNumber)
            .maybeSingle();

        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This Aadhar is already registered. Please login.'), backgroundColor: AppTheme.classicCrimson),
            );
            setState(() => _isLoading = false);
          }
          return;
        }

        // Call the Face API to ensure it's a real face & register them
        if (!_isEmulatorBypass) {
          final faceError = await _registerFaceOnBackend(aadharNumber);
          if (faceError != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('AI Check Failed: $faceError'), backgroundColor: AppTheme.classicCrimson),
              );
              setState(() => _isLoading = false);
            }
            return;
          }
        }

        // Create new profile with PIN
        await supabase.from('profiles').insert({
          'id': aadharNumber,
          'full_name': name,
          'pin': pin,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful. Welcome!'), backgroundColor: Colors.green),
          );

          // Head directly into the app
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => UserMainScreen(id: aadharNumber),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.classicCrimson),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aadharController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('CITIZEN REGISTRATION'),
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
                  Text('REGISTRATION OFFICE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.inkyNavy)),
                  const Divider(),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('NEW RECORD ENTRY',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'FULL NAME (As per Aadhar)', prefixIcon: Icon(Icons.person_outline)),
                              validator: (v) => v!.isEmpty ? 'Please enter your full name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _aadharController,
                              keyboardType: TextInputType.number,
                              maxLength: 12,
                              decoration: const InputDecoration(labelText: 'AADHAR NUMBER', prefixIcon: Icon(Icons.badge_outlined)),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter Aadhar number';
                                if (v.length != 12) return 'Aadhar must be exactly 12 digits';
                                if (int.tryParse(v) == null) return 'Must be numbers only';
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
                                labelText: 'CREATE 6-DIGIT PIN',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please create a PIN';
                                if (v.length != 6) return 'PIN must be exactly 6 digits';
                                if (int.tryParse(v) == null) return 'Must be numbers only';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPinController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              obscureText: _obscureConfirmPin,
                              decoration: InputDecoration(
                                labelText: 'CONFIRM 6-DIGIT PIN',
                                prefixIcon: const Icon(Icons.verified_user_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPin ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                                ),
                              ),
                              validator: (v) {
                                if (v != _pinController.text) return 'PINs do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // CAPTCHA ROW
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.paperBackground,
                                border: Border.all(color: AppTheme.borderInk),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _captchaText,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 8.0,
                                        color: AppTheme.inkyNavy,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: AppTheme.pencilGrey),
                                    onPressed: _generateCaptcha,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _captchaController,
                              decoration: const InputDecoration(labelText: 'ENTER CAPTCHA CODE ABOVE'),
                              validator: (v) => v!.isEmpty ? 'Please enter captcha' : null,
                            ),
                            const SizedBox(height: 24),
                            
                            // ── BIOMETRIC CAPTURE ──
                            InkWell(
                              onTap: _pickPhoto,
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _localPhoto != null ? Colors.green : AppTheme.borderInk, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                  color: _localPhoto != null ? Colors.green.withOpacity(0.05) : Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(_localPhoto != null ? Icons.check_circle : Icons.camera_alt_outlined, 
                                         color: _localPhoto != null ? Colors.green : AppTheme.inkyNavy),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _localPhoto != null ? 'FACE ID CAPTURED' : 'CAPTURE BIOMETRIC FACE ID',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _localPhoto != null ? Colors.green : AppTheme.inkyNavy,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    if (_localPhoto != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(_localPhoto!, width: 40, height: 40, fit: BoxFit.cover),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              value: _isEmulatorBypass,
                              onChanged: (v) => setState(() => _isEmulatorBypass = v ?? false),
                              title: const Text('Emulator / Debug Bypass', style: TextStyle(fontSize: 12)),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: _isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.how_to_reg),
                              label: Text(_isLoading ? 'PROCESSING...' : 'REGISTER'),
                              onPressed: _isLoading ? null : _handleSubmit,
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
                      const Text('Already have a record? ', style: TextStyle(color: AppTheme.pencilGrey, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'CITIZEN LOGIN',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
