import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:sih/services/api_service.dart';

class AdminIssueViewPage extends StatefulWidget {
  const AdminIssueViewPage({super.key});

  @override
  State<AdminIssueViewPage> createState() => _AdminIssueViewPageState();
}

class _AdminIssueViewPageState extends State<AdminIssueViewPage> {
  final supabase = Supabase.instance.client;

  final List<String> categories = [
    'ALL', 'ROAD', 'WATER', 'ELECTRICITY', 'SANITATION',
    'TREE', 'STRAY ANIMALS', 'NOISE', 'TRAFFIC', 'BUILDING',
    'FIRE HAZARD', 'PUBLIC HEALTH', 'CRIME', 'FLOOD DRAINAGE', 'UNCATEGORISED'
  ];
  String selectedCategory = 'ALL';

  final Map<String, String> _updatingMap = {};
  final Set<String> _optimisticallyHidden = {}; // Track IDs to hide immediately
  bool _isCategorizing = false;
  Stream<List<Map<String, dynamic>>>? _issueStream;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    super.dispose();
  }

  void _initStream() {
    _issueStream = supabase
        .from('issues')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () async {
      if (!mounted) return;
      // Wake up the Supabase project before reconnecting
      try {
        await supabase.from('issues').select().limit(1);
      } catch (_) {}
      if (mounted) setState(() => _initStream());
    });
  }

  Future<void> _refreshData() async {
    _reconnectTimer?.cancel();
    if (mounted) setState(() => _initStream());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPLETION LOG DIALOG — opens before marking COMPLETED
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _showCompletionDialog(String issueId) async {
    final noteCtrl = TextEditingController();
    final authorityCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    File? proofImage;
    String? proofImagePath;
    bool isUploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.inkyNavy,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'COMPLETION LOG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Work Note ──
                    const Text('WORK DONE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Describe the work completed...',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Authority ──
                    const Text('AUTHORITY / VERIFIED BY',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: authorityCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Ward Officer - Block 4',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Date ──
                    const Text('DATE OF COMPLETION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderInk),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 16, color: AppTheme.inkyNavy),
                            const SizedBox(width: 8),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Proof Image ──
                    const Text('PROOF IMAGE (Optional)',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          imageQuality: 75,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            proofImage = File(picked.path);
                            proofImagePath = picked.path;
                          });
                        }
                      },
                      child: Container(
                        height: proofImage != null ? 140 : 72,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderInk),
                          color: AppTheme.paperBackground,
                        ),
                        child: proofImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(proofImage!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 4, right: 4,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setDialogState(() => proofImage = null),
                                      child: Container(
                                        color: Colors.black54,
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: AppTheme.inkyNavy, size: 28),
                                  SizedBox(height: 4),
                                  Text('Tap to add proof',
                                      style: TextStyle(
                                          fontSize: 11, color: AppTheme.pencilGrey)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('CANCEL',
                      style: TextStyle(color: AppTheme.pencilGrey, fontSize: 11)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                  ),
                  icon: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check, size: 16),
                  label: Text(isUploading ? 'SAVING...' : 'CONFIRM & COMPLETE',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (noteCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please describe the work done.'),
                                  backgroundColor: Colors.red),
                            );
                            return;
                          }
                          setDialogState(() => isUploading = true);

                          String? proofUrl;
                          try {
                            // Upload proof image if provided
                            if (proofImage != null) {
                              final fileName =
                                  'proof_${issueId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                              final bytes = await proofImage!.readAsBytes();
                              await supabase.storage
                                  .from('drishti')
                                  .uploadBinary(fileName, bytes,
                                      fileOptions: const FileOptions(
                                          contentType: 'image/jpeg'));
                              proofUrl = supabase.storage
                                  .from('drishti')
                                  .getPublicUrl(fileName);
                            }

                            // Update Supabase with all completion details
                            final response = await supabase.from('issues').update({
                              'status': 'COMPLETED',
                              'completion_note':
                                  noteCtrl.text.trim(),
                              'completion_date':
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              'completion_authority':
                                  authorityCtrl.text.trim().isEmpty
                                      ? null
                                      : authorityCtrl.text.trim(),
                              'completion_proof_url': proofUrl,
                            }).eq('id', issueId).select();

                            if (response.isEmpty) {
                              throw Exception('Issue not found or no permission to update.');
                            }

                            if (mounted) {
                              setState(() {
                                _optimisticallyHidden.add(issueId);
                              });
                              Navigator.of(dialogCtx).pop(); // close dialog
                              _refreshData(); // Force UI sync
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(children: [
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Issue marked as COMPLETED'),
                                  ]),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isUploading = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIMPLE STATUS UPDATE (IN PROGRESS / REJECTED — no log needed)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _updateIssueStatus(String id, String newStatus) async {
    setState(() => _updatingMap[id] = newStatus);
    try {
      final response = await supabase
          .from('issues')
          .update({'status': newStatus})
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw Exception('Issue not found or update failed.');
      }

      if (mounted) {
        setState(() {
          _optimisticallyHidden.add(id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(
                newStatus == 'IN PROGRESS'
                    ? Icons.timelapse
                    : Icons.block_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Marked as $newStatus'),
            ]),
            backgroundColor: _statusColor(newStatus),
            duration: const Duration(seconds: 2),
          ),
        );
        _refreshData(); // Force UI sync
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingMap.remove(id));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REJECTION LOG DIALOG — opens before marking REJECTED
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _showRejectDialog(String issueId) async {
    final reasonCtrl = TextEditingController();
    final authorityCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'REJECTION LOG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('REASON FOR REJECTION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Describe why this issue is being rejected...',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('REJECTED BY (AUTHORITY)',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: authorityCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Sanitation Department Head',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('DATE OF REJECTION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.pencilGrey)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderInk),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 16, color: AppTheme.inkyNavy),
                            const SizedBox(width: 8),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('CANCEL',
                      style: TextStyle(color: AppTheme.pencilGrey, fontSize: 11)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (reasonCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please provide a reason.'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            final resp = await supabase.from('issues').update({
                              'status': 'REJECTED',
                              'rejection_note': reasonCtrl.text.trim(),
                              'rejection_date': '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              'rejection_authority': authorityCtrl.text.trim().isEmpty ? null : authorityCtrl.text.trim(),
                            }).eq('id', issueId).select();

                            if (resp.isEmpty) throw Exception('Update failed');

                            if (mounted) {
                              setState(() => _optimisticallyHidden.add(issueId));
                              Navigator.of(dialogCtx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Issue REJECTED'), backgroundColor: Colors.red),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                  child: Text(isSaving ? 'SAVING...' : 'CONFIRM REJECT',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUTO-SORT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _categorizeAll() async {
    setState(() => _isCategorizing = true);
    try {
      final uncategorised = await supabase
          .from('issues')
          .select()
          .eq('category', 'UNCATEGORISED');

      if (uncategorised.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No uncategorised issues found.'),
                backgroundColor: Colors.green),
          );
        }
        return;
      }

      int count = 0;
      for (final issue in uncategorised) {
        final String id = issue['id'].toString();
        final String description = issue['description'] ?? '';
        final String? imageUrl = issue['image_url'];
        final double lat = (issue['latitude'] ?? 0.0).toDouble();
        final double lon = (issue['longitude'] ?? 0.0).toDouble();

        String category = 'UNCATEGORISED';
        double confidence = 0.0;
        String priority = 'Low';
        try {
          final result = await ApiService.categorizeFromText(
            description: description,
            imageUrl: imageUrl,
            lat: lat,
            lon: lon,
          );
          category = _mapCategory(result['category']?.toString() ?? '');
          confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
          priority = (result['priority']?.toString() ?? 'Low');
        } catch (_) {
          category = _keywordCategorize(description);
          confidence = category != 'UNCATEGORISED' ? 60.0 : 0.0;
          // default keyword mapping
          priority = 'Low'; 
        }

        if (category != 'UNCATEGORISED') {
          debugPrint('[AUTO-SORT] Updating id=$id → category=$category (${confidence.toStringAsFixed(1)}%) | Priority: $priority');
          final updateResp = await supabase
              .from('issues')
              .update({'category': category, 'ai_confidence': confidence, 'priority': priority})
              .eq('id', id)
              .select();
          if (updateResp.isEmpty) {
            debugPrint('[AUTO-SORT] ⚠️ Update returned empty! RLS may be blocking category updates.');
          } else {
            debugPrint('[AUTO-SORT] ✅ Success: $updateResp');
            count++;
          }
        } else {
          debugPrint('[AUTO-SORT] ⏩ Skipping id=$id (no matching category for: "$description")');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-sorted $count / ${uncategorised.length} issues'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sort error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCategorizing = false);
    }
  }

  String _mapCategory(String pred) {
    final p = pred.toUpperCase().trim();
    const valid = [
      'ROAD', 'WATER', 'ELECTRICITY', 'SANITATION',
      'TREE', 'STRAY ANIMALS', 'NOISE', 'TRAFFIC', 'BUILDING',
      'FIRE HAZARD', 'PUBLIC HEALTH', 'CRIME', 'FLOOD DRAINAGE'
    ];
    if (valid.contains(p)) return p;
    if (p.contains('ROAD') || p.contains('POTHOLE')) return 'ROAD';
    if (p.contains('WATER') || p.contains('LEAK')) return 'WATER';
    if (p.contains('ELECTR') || p.contains('LIGHT')) return 'ELECTRICITY';
    if (p.contains('SANIT') || p.contains('GARBAGE') || p.contains('TRASH')) return 'SANITATION';
    if (p.contains('TREE') || p.contains('PARK')) return 'TREE';
    if (p.contains('STRAY') || p.contains('ANIMAL')) return 'STRAY ANIMALS';
    if (p.contains('NOISE') || p.contains('SOUND')) return 'NOISE';
    if (p.contains('TRAFFIC') || p.contains('SIGNAL')) return 'TRAFFIC';
    if (p.contains('BUILD') || p.contains('CONSTRUCT')) return 'BUILDING';
    if (p.contains('FIRE') || p.contains('GAS') || p.contains('HAZARD')) return 'FIRE HAZARD';
    if (p.contains('HEALTH') || p.contains('MOSQUITO')) return 'PUBLIC HEALTH';
    if (p.contains('CRIME') || p.contains('CCTV')) return 'CRIME';
    if (p.contains('DRAIN') || p.contains('FLOOD')) return 'FLOOD DRAINAGE';
    return 'UNCATEGORISED';
  }

  String _keywordCategorize(String text) {
    final t = text.toLowerCase();
    if (t.contains('pothole') || t.contains('road') || t.contains('pavement') || t.contains('sadak') || t.contains('gaddha')) return 'ROAD';
    if (t.contains('water') || t.contains('leak') || t.contains('paani') || t.contains('pipe') || t.contains('tanki')) return 'WATER';
    if (t.contains('light') || t.contains('electric') || t.contains('bijli') || t.contains('pole') || t.contains('dark')) return 'ELECTRICITY';
    if (t.contains('garbage') || t.contains('trash') || t.contains('waste') || t.contains('kachra') || t.contains('smell')) return 'SANITATION';
    if (t.contains('tree') || t.contains('park') || t.contains('ped') || t.contains('fallen') || t.contains('bench')) return 'TREE';
    if (t.contains('dog') || t.contains('cow') || t.contains('animal') || t.contains('stray') || t.contains('aawara')) return 'STRAY ANIMALS';
    if (t.contains('noise') || t.contains('loud') || t.contains('shor') || t.contains('speaker')) return 'NOISE';
    if (t.contains('traffic') || t.contains('signal') || t.contains('parking') || t.contains('jam')) return 'TRAFFIC';
    if (t.contains('building') || t.contains('construction') || t.contains('encroach') || t.contains('wall')) return 'BUILDING';
    if (t.contains('fire') || t.contains('aag') || t.contains('gas') || t.contains('smoke') || t.contains('hazard')) return 'FIRE HAZARD';
    if (t.contains('health') || t.contains('mosquito') || t.contains('disease') || t.contains('bimari')) return 'PUBLIC HEALTH';
    if (t.contains('crime') || t.contains('cctv') || t.contains('unsafe') || t.contains('theft')) return 'CRIME';
    if (t.contains('drain') || t.contains('naali') || t.contains('waterlog') || t.contains('barish')) return 'FLOOD DRAINAGE';
    return 'UNCATEGORISED';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'IN PROGRESS':
        return Colors.orange.shade700;
      case 'REJECTED':
        return Colors.red.shade700;
      default:
        return AppTheme.inkyNavy;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISSUE MANAGEMENT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: _refreshData,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category filter tabs ──
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppTheme.borderInk, width: 0.8)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.inkyNavy : Colors.transparent,
                      border: Border.all(color: AppTheme.inkyNavy, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppTheme.inkyNavy,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Auto-Sort banner (ALL tab only) ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectedCategory == 'ALL'
                ? Container(
                    key: const ValueKey('autosort'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F0),
                      border: Border(
                        bottom:
                            BorderSide(color: AppTheme.borderInk, width: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_outlined,
                            size: 14, color: AppTheme.pencilGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Uncategorised issues can be sorted automatically.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.pencilGrey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _isCategorizing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.inkyNavy),
                              )
                            : TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  side: const BorderSide(
                                      color: AppTheme.inkyNavy, width: 1),
                                  foregroundColor: AppTheme.inkyNavy,
                                  shape: const RoundedRectangleBorder(),
                                ),
                                onPressed: _categorizeAll,
                                icon: const Icon(Icons.play_arrow, size: 14),
                                label: const Text('AUTO-SORT',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-autosort')),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _issueStream,
              builder: (context, snapshot) {
                if (snapshot.hasError ||
                    snapshot.connectionState == ConnectionState.done) {
                  _scheduleReconnect();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_outlined,
                              size: 48, color: AppTheme.pencilGrey),
                          const SizedBox(height: 12),
                          const Text(
                            'Connection lost. Reconnecting…',
                            textAlign: TextAlign.center,
                          ),
                          if (snapshot.hasError) ...[
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('RETRY NOW'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = snapshot.data!.where((i) {
                  final id = i['id'].toString();
                  // Hide if optimistically marked as done
                  if (_optimisticallyHidden.contains(id)) return false;

                  final status =
                      (i['status'] ?? '').toString().toUpperCase().trim();
                  final cat =
                      (i['category'] ?? '').toString().toUpperCase().trim();
                  return status == 'SUBMITTED' &&
                      (selectedCategory == 'ALL' ||
                          cat == selectedCategory);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 56,
                            color: AppTheme.pencilGrey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('No pending issues.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.pencilGrey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppTheme.inkyNavy,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildIssueCard(filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildIssueCard(Map<String, dynamic> issue) {
    final id = issue['id'].toString();
    final description = issue['description'] ?? '';
    final latitude = issue['latitude'];
    final longitude = issue['longitude'];
    final status =
        (issue['status'] ?? 'SUBMITTED').toString().toUpperCase().trim();
    final imageUrl = issue['image_url'];
    final category =
        (issue['category'] ?? 'UNCATEGORISED').toString().toUpperCase().trim();
    final createdAt =
        DateTime.tryParse(issue['created_at'] ?? '') ?? DateTime.now();
    final isUpdating = _updatingMap.containsKey(id);

    final priority = (issue['priority'] ?? 'Low').toString();
    final upvotes = (issue['upvotes'] ?? 0) as int;

    final borderColor = status == 'IN PROGRESS'
        ? Colors.orange.shade600
        : AppTheme.borderInk;
        
    Color priorityColor = Colors.grey;
    if (priority == 'Critical') priorityColor = Colors.red.shade800;
    else if (priority == 'High') priorityColor = Colors.orange.shade800;
    else if (priority == 'Medium') priorityColor = Colors.amber.shade700;
    else priorityColor = Colors.green.shade700;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
            color: borderColor,
            width: status == 'IN PROGRESS' ? 2.0 : 0.8),
      ),
      child: ExpansionTile(
        shape: const Border.fromBorderSide(BorderSide.none),
        tilePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(color: borderColor.withOpacity(0.3), width: 0.8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FILE #${id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.pencilGrey,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.inkyNavy),
                        ),
                        if (issue['ai_confidence'] != null && (issue['ai_confidence'] as num) > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'AI: ${(issue['ai_confidence'] as num).toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 8, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: priorityColor.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(2),
                            color: priorityColor.withOpacity(0.1),
                          ),
                          child: Text('PRIORITY: ${priority.toUpperCase()}', style: TextStyle(fontSize: 8, color: priorityColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 8),
                        if (upvotes > 0)
                          Row(
                            children: [
                              Icon(Icons.thumb_up_alt_outlined, size: 10, color: AppTheme.pencilGrey),
                              const SizedBox(width: 2),
                              Text('$upvotes', style: const TextStyle(fontSize: 10, color: AppTheme.pencilGrey, fontWeight: FontWeight.w600)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(status),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _statusColor(status), width: 1),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          if (latitude != null && longitude != null)
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppTheme.pencilGrey),
              const SizedBox(width: 4),
              Text(
                '$latitude, $longitude',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.pencilGrey),
              ),
            ]),
          const SizedBox(height: 8),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, prog) => prog == null
                    ? child
                    : Container(
                        height: 200,
                        color: AppTheme.inkyNavy.withOpacity(0.05),
                        child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2))),
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: AppTheme.inkyNavy.withOpacity(0.05),
                  child: const Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: AppTheme.inkyNavy)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${createdAt.toLocal().toString().substring(0, 16)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.pencilGrey, fontSize: 10),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // ── Action buttons ──
          isUpdating
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.inkyNavy)),
                        const SizedBox(width: 12),
                        Text(
                          'Updating...',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.pencilGrey),
                        ),
                      ],
                    ),
                  ),
                )
              : Row(
                  children: [
                    // COMPLETED — opens the log dialog first
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: const RoundedRectangleBorder()),
                        onPressed: () => _showCompletionDialog(id),
                        icon: const Icon(Icons.check_circle_outline, size: 13),
                        label: const Text('COMPLETED',
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: const RoundedRectangleBorder()),
                        onPressed: () =>
                            _updateIssueStatus(id, 'IN PROGRESS'),
                        icon: const Icon(Icons.timelapse_outlined, size: 13),
                        label: const Text('PROGRESS',
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade700),
                            foregroundColor: Colors.red.shade700,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: const RoundedRectangleBorder()),
                        onPressed: () => _showRejectDialog(id),
                        icon: const Icon(Icons.block_outlined, size: 13),
                        label: const Text('REJECT',
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
