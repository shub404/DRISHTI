import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportIssuePage extends StatefulWidget {
  String? id;
  ReportIssuePage({super.key, required this.id});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  File? _image;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late DocumentReference userDoc;
  late CollectionReference submittedIssues;

  
  Location location = new Location();
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;

  Future<void> _requestLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if(!_serviceEnabled){
      _serviceEnabled = await location.requestService();
      if(!_serviceEnabled){
        return;
      }
    }
    
    _permissionGranted = await location.hasPermission();
    if(_permissionGranted == PermissionStatus.denied){
      _permissionGranted = await location.requestPermission();
      if(_permissionGranted != PermissionStatus.granted){
        return;
      }
    }

    _locationData = await location.getLocation();
    
  }
  Future<void> _showImageSourceSelector() async {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, size: 40),
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Text("Camera"),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, size: 40),
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Text("Gallery"),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    setState(() {
      _image = File(pickedFile.path);
    });
  }
}

  void _handleSubmit() async {
  if (_formKey.currentState?.validate() ?? false) {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _requestLocation();

      CollectionReference issues = firestore.collection('issues');
      CollectionReference categories = firestore.collection('admin').doc('issues').collection('uncategorised');
      
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("issue_images")
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      
      await submittedIssues.doc('${_descriptionController.text}').set({
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': _locationData?.latitude,
        'longitude': _locationData?.longitude,
        'status': 'SUBMITTED',
        'image_url': downloadUrl, 
        'category': "UNCATEGORISED",
        'userID': widget.id ,
      });

      await issues.doc('${_descriptionController.text}').set({
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': _locationData?.latitude,
        'longitude': _locationData?.longitude,
        'status': 'SUBMITTED',
        'image_url': downloadUrl, 
        'category': "UNCATEGORISED",
        'userID': widget.id ,
      });
  
      await categories.doc('${_descriptionController.text}').set({
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': _locationData?.latitude,
        'longitude': _locationData?.longitude,
        'status': 'SUBMITTED',
        'image_url': downloadUrl, 
        'category': "UNCATEGORISED",
        'userID': widget.id ,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}



  
  @override
  void initState() {
    super.initState();
    userDoc = firestore.collection('users').doc('${widget.id}');
    submittedIssues = userDoc.collection('submittedIssues');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
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
                            Text('Report Issue',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Issue Description',
                                alignLabelWithHint: true,
                              ),
                              minLines: 4,
                              maxLines: 6,
                              validator: (value) => value!.trim().isEmpty
                                  ? 'Please provide an issue description'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            const Text('Upload Photo (Required)', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showImageSourceSelector,
                              child: DottedBorder(
                                color: Colors.grey[400]!,
                                strokeWidth: 1.5,
                                dashPattern: const [6, 4],
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(12),
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _image != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(11),
                                          child: Image.file(_image!, fit: BoxFit.contain),
                                        )
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.upload_file, size: 40, color: AppTheme.subtleTextColor),
                                            SizedBox(height: 8),
                                            Text('Click to upload image', style: TextStyle(color: AppTheme.subtleTextColor)),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                             ElevatedButton.icon(
                                icon: _isSubmitting
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Issue'),
                                onPressed: _isSubmitting ? null : _handleSubmit,
                                style: Theme.of(context)
                                    .elevatedButtonTheme
                                    .style
                                    ?.copyWith(
                                      backgroundColor:
                                          MaterialStateProperty.all(AppTheme.primaryBlue),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}