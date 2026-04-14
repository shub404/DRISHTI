import 'package:flutter/material.dart';
import 'package:sih/pages/admin_login_page.dart';
import 'package:sih/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AadharLoginPage extends StatefulWidget {
  const AadharLoginPage({super.key});

  @override
  State<AadharLoginPage> createState() => _AadharLoginPageState();
}

class _AadharLoginPageState extends State<AadharLoginPage> {
  final _aadharController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _handleSubmit() async {
  if (_formKey.currentState?.validate() ?? false) {
    setState(() => _isLoading = true);

    try {
      String aadharNumber = _aadharController.text.trim();

      if (aadharNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Aadhar number'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        await FirebaseFirestore.instance.collection('users').doc(aadharNumber).set({
          'aadhar': aadharNumber,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => HomePage(id: aadharNumber),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}


  @override
  void dispose() {
    _aadharController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Aadhar Login',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _aadharController,
                                decoration: const InputDecoration(
                                  labelText: 'Aadhar Number',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.account_box),
                                ), 
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your Aadhar number';
                                  }
                                },
                                maxLength: 12,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Login'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: GestureDetector(
                      child: Text("ADMIN?"),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> AdminLoginPage()));
                      },
                      ),
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