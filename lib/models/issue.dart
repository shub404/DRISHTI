class Issue {
  final String id;
  final String description;
  final String? imageUrl;
  final DateTime timestamp;

  Issue({
    required this.id,
    required this.description,
    this.imageUrl,
    required this.timestamp,
  });
}