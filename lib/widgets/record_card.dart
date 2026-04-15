import 'package:flutter/material.dart';
import 'package:sih/theme/app_theme.dart';

class RecordCard extends StatelessWidget {
  final Map<String, dynamic> issue;
  final int? index;
  final bool compact;
  final VoidCallback? onTap;
  final String? distanceLabel;
  final Widget? actionButtons;
  const RecordCard({
    super.key,
    required this.issue,
    this.index,
    this.compact = false,
    this.onTap,
    this.distanceLabel,
    this.actionButtons,
  });
  String _formatDate(String? isoString) {
    if (isoString == null) return "";
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "";
    }
  }

  Color _statusColor(String status) {
    switch (status) {
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

  Widget _officialNoteBox({
    required String title,
    required String note,
    String? authority,
    String? date,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(fontSize: 12, height: 1.4)),
          if (authority != null || date != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (authority != null)
                  Expanded(
                    child: Text(
                      "AUTHORITY: ${authority.toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.pencilGrey,
                      ),
                    ),
                  ),
                if (date != null)
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppTheme.pencilGrey,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = issue['description'] ?? '';
    final latitude = issue['latitude'];
    final longitude = issue['longitude'];
    final status = (issue['status'] ?? 'UNKNOWN').toString().toUpperCase();
    final imageUrl = issue['image_url'] ?? '';
    final category = (issue['category'] ?? 'UNCATEGORISED')
        .toString()
        .toUpperCase();
    final completionProofUrl = issue['completion_proof_url'];
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderInk, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          category,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.pencilGrey,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (distanceLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            distanceLabel!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.pencilGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderInk, width: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    index != null ? 'FILE NO. #${index! + 101}' : 'RECORD',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.inkyNavy,
                      fontSize: 10,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.inkyNavy, width: 1),
                    ),
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.inkyNavy,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 16),
                        ),
                      ),
                      Text(
                        _formatDate(issue['created_at']),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.pencilGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (imageUrl.isNotEmpty && completionProofUrl == null)
                    _buildImage(imageUrl)
                  else if (imageUrl.isNotEmpty && completionProofUrl != null)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                "BEFORE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.pencilGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildImage(imageUrl, height: 140),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                "AFTER",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildImage(completionProofUrl, height: 140),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (status == 'REJECTED' && issue['rejection_note'] != null)
                    _officialNoteBox(
                      title: 'OFFICIAL REJECTION NOTE',
                      note: issue['rejection_note'],
                      authority: issue['rejection_authority'],
                      date: issue['rejection_date'],
                      color: Colors.red.shade800,
                    ),
                  if (status == 'COMPLETED' && issue['completion_note'] != null)
                    _officialNoteBox(
                      title: 'OFFICIAL RESOLUTION LOG',
                      note: issue['completion_note'],
                      authority: issue['completion_authority'],
                      date: issue['completion_date'],
                      color: Colors.green.shade800,
                    ),
                  if (status != 'SUBMITTED' &&
                      status != 'REJECTED' &&
                      status != 'COMPLETED')
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        "ADMIN NOTE: Processing and verification is ongoing.",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (actionButtons != null) ...[
                    const Divider(),
                    actionButtons!,
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.tag_outlined,
                        size: 14,
                        color: AppTheme.pencilGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.pencilGrey,
                        ),
                      ),
                      const Spacer(),
                      if (latitude != null && longitude != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppTheme.pencilGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.pencilGrey),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url, {double height = 200}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderInk, width: 0.5),
        ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: height,
                color: AppTheme.inkyNavy.withValues(alpha: 0.05),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: height,
                color: AppTheme.inkyNavy.withValues(alpha: 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTheme.inkyNavy.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UNAVAILABLE',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              );
            },
          ),
      ),
    );
  }
}
