class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category; // 'streaks' | 'total' | 'consistency' | 'category'
  final String? unlockedAt;
  final String requirementText;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.unlockedAt,
    required this.requirementText,
  });

  bool get isUnlocked => unlockedAt != null;

  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        category: json['category'] as String,
        unlockedAt: json['unlockedAt'] as String?,
        requirementText: json['requirementText'] as String,
      );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'requirementText': requirementText,
    };
    if (unlockedAt != null) m['unlockedAt'] = unlockedAt;
    return m;
  }

  BadgeModel copyWith({String? unlockedAt}) => BadgeModel(
        id: id,
        title: title,
        description: description,
        icon: icon,
        category: category,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        requirementText: requirementText,
      );
}
