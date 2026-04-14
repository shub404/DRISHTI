import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/services/api_service.dart';
import 'package:sih/services/draft_service.dart';

class ReportIssuePage extends StatefulWidget {
  final String? id;

  /// If provided, the form will be pre-filled with the draft's content.
  /// The draft will be deleted from local storage after a successful submit.
  final DraftReport? draftToEdit;

  /// Index of the draft in the draft list (needed to delete it after submit)
  final int? draftIndex;

  const ReportIssuePage({
    super.key,
    required this.id,
    this.draftToEdit,
    this.draftIndex,
  });

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  File? _image;

  final supabase = Supabase.instance.client;
  final Location location = Location();
  LocationData? _locationData;

  final ValueNotifier<String> _statusNotifier = ValueNotifier('Initializing...');
  bool _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from draft if one was passed in
    if (widget.draftToEdit != null) {
      final d = widget.draftToEdit!;
      _descriptionController.text = d.description;
      if (d.imagePath != null && File(d.imagePath!).existsSync()) {
        _image = File(d.imagePath!);
      }
      if (d.lat != null && d.lon != null) {
        _locationData = null; // Will re-fetch fresh location on submit
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _statusNotifier.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }
      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }
      _locationData = await location.getLocation().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Location failed (non-critical): $e");
    }
  }

  Future<void> _showImageSourceSelector() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sourceOption(Icons.camera_alt, "Camera", ImageSource.camera),
            _sourceOption(Icons.photo_library, "Gallery", ImageSource.gallery),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.inkyNavy),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<void> _saveDraft() async {
    final draft = DraftReport(
      description: _descriptionController.text,
      imagePath: _image?.path,
      lat: _locationData?.latitude,
      lon: _locationData?.longitude,
      timestamp: DateTime.now(),
    );
    // If editing an existing draft, delete it first to avoid duplicates
    if (widget.draftIndex != null) {
      await DraftService.deleteDraft(widget.draftIndex!);
    }
    await DraftService.saveDraft(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Saved as local draft'),
            backgroundColor: AppTheme.inkyNavy),
      );
      Navigator.pop(context);
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: const RoundedRectangleBorder(),
          title: const Row(
            children: [
              Icon(Icons.upload_outlined, color: AppTheme.inkyNavy, size: 20),
              SizedBox(width: 8),
              Text('SUBMITTING REPORT',
                  style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LinearProgressIndicator(
                  backgroundColor: AppTheme.borderInk,
                  color: AppTheme.inkyNavy),
              const SizedBox(height: 20),
              ValueListenableBuilder<String>(
                valueListenable: _statusNotifier,
                builder: (_, status, __) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    status,
                    key: ValueKey(status),
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.pencilGrey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.save_outlined,
                  size: 16, color: AppTheme.classicCrimson),
              label: const Text('CANCEL & SAVE DRAFT',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.classicCrimson)),
              onPressed: () {
                _cancelRequested = true;
                Navigator.of(dialogContext).pop();
                _saveDraft();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please attach an image'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _cancelRequested = false;
    _statusNotifier.value = 'Getting your location...';
    _showProgressDialog();

    try {
      await _requestLocation();
      if (_cancelRequested) return;

      _statusNotifier.value = 'Verifying identity...';
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final duplicates = await supabase
          .from('issues')
          .select()
          .eq('user_id', widget.id ?? "")
          .gt('created_at', oneHourAgo.toIso8601String());

      if (duplicates.isNotEmpty) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A recent report is already under review.'),
              backgroundColor: AppTheme.inkyNavy),
        );
        return;
      }
      if (_cancelRequested) return;

      _statusNotifier.value = 'Analyzing image & uploading...';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageBytes = await _image!.readAsBytes();

      final results = await Future.wait([
        supabase.storage.from('drishti').uploadBinary(
              fileName,
              imageBytes,
              fileOptions:
                  const FileOptions(contentType: 'image/jpeg'),
            ),
        ApiService.categorizeIssue(
          image: _image!,
          lat: _locationData?.latitude ?? 0.0,
          lon: _locationData?.longitude ?? 0.0,
          description: _descriptionController.text,
        ).catchError((e) {
          debugPrint("AI categorisation skipped: $e");
          return {'category': 'uncategorised'} as dynamic;
        }),
      ]);

      if (_cancelRequested) return;

      final String downloadUrl =
          supabase.storage.from('drishti').getPublicUrl(fileName);
      final aiResult = results[1] as Map<String, dynamic>;
      final String category =
          _mapCategory(aiResult['category']?.toString() ?? '');

      _statusNotifier.value = 'Saving official record...';
      await supabase.from('issues').insert({
        'user_id': widget.id,
        'description': _descriptionController.text,
        'category': category,
        'latitude': _locationData?.latitude,
        'longitude': _locationData?.longitude,
        'image_url': downloadUrl,
        'status': 'SUBMITTED',
      });

      if (_cancelRequested) return;

      // If this was a draft, delete it from local storage now
      if (widget.draftIndex != null) {
        await DraftService.deleteDraft(widget.draftIndex!);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Issue reported successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Submit error: $e");
      if (mounted && !_cancelRequested) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'SAVE DRAFT',
              textColor: Colors.white,
              onPressed: _saveDraft,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _mapCategory(String pred) {
    final p = pred.toLowerCase();
    if (p.contains('pothole') || p.contains('road')) return 'ROAD';
    if (p.contains('water')) return 'WATER';
    if (p.contains('light') || p.contains('electr')) return 'ELECTRICITY';
    if (p.contains('garbage') || p.contains('sanit') || p.contains('waste'))
      return 'SANITATION';
    return 'UNCATEGORISED';
  }

  @override
  Widget build(BuildContext context) {
    final isDraftEdit = widget.draftToEdit != null;

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
          title: Text(isDraftEdit ? 'EDIT DRAFT' : 'NEW REPORT'),
          actions: isDraftEdit
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.classicCrimson),
                    tooltip: 'Delete draft',
                    onPressed: () async {
                      if (widget.draftIndex != null) {
                        await DraftService.deleteDraft(widget.draftIndex!);
                      }
                      if (mounted) Navigator.pop(context);
                    },
                  )
                ]
              : null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDraftEdit)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_outlined,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Editing draft saved on ${widget.draftToEdit!.timestamp.toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text('INCIDENT STATEMENT',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.inkyNavy),
                    textAlign: TextAlign.center),
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
                          Text('Description of Issue',
                              style:
                                  Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Describe the incident in detail...',
                              alignLabelWithHint: true,
                            ),
                            minLines: 5,
                            maxLines: 10,
                            validator: (v) => v!.trim().isEmpty
                                ? 'Please describe the issue'
                                : null,
                          ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text('EVIDENCE (Required)',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                      color: AppTheme.inkyNavy)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : _showImageSourceSelector,
                            child: DottedBorder(
                              color: AppTheme.borderInk,
                              strokeWidth: 1.0,
                              dashPattern: const [4, 4],
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(4),
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                color: AppTheme.paperBackground,
                                child: _image != null
                                    ? Stack(children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          child: Image.file(_image!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                                () => _image = null),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(4),
                                              color: Colors.black54,
                                              child: const Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 16),
                                            ),
                                          ),
                                        ),
                                      ])
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                              Icons.add_a_photo_outlined,
                                              size: 48,
                                              color: AppTheme.inkyNavy),
                                          const SizedBox(height: 12),
                                          Text(
                                            'ATTACH PHOTOGRAPH',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                    color:
                                                        AppTheme.inkyNavy),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          ElevatedButton.icon(
                            icon: const Icon(
                                Icons.assignment_turned_in_outlined),
                            label: const Text('SUBMIT OFFICIAL REPORT'),
                            onPressed:
                                _isSubmitting ? null : _handleSubmit,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _saveDraft,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('SAVE AS LOCAL DRAFT'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                Text('DRISHTI VERIFICATION SYSTEM',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.pencilGrey, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}