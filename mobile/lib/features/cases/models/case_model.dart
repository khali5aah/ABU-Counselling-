enum CaseStatus { open, inProgress, closed }

class CaseModel {
  final String id;
  final String pseudonym; // Anonymized student identifier (e.g., "Pink Flame")
  final String category;  // e.g., "Academic Stress", "Personal Guidance"
  final String description;
  final CaseStatus status;
  final DateTime createdAt;

  const CaseModel({
    required this.id,
    required this.pseudonym,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pseudonym': pseudonym,
        'category': category,
        'description': description,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
        id: json['id'] as String,
        pseudonym: json['pseudonym'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        status: CaseStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}