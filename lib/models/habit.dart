class Habit {
  final String id;
  final String name;
  final String description;
  final String category;
  final String type; // 'boolean' | 'numeric' | 'timer'
  final String timeOfDay; // 'morning' | 'afternoon' | 'evening' | 'anytime'
  final int targetValue;
  final String targetUnit;
  final String createdAt;
  final String color;
  final String icon;
  final bool isArchived;

  const Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    required this.timeOfDay,
    required this.targetValue,
    required this.targetUnit,
    required this.createdAt,
    required this.color,
    required this.icon,
    required this.isArchived,
  });

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String,
        type: json['type'] as String,
        timeOfDay: json['timeOfDay'] as String,
        targetValue: (json['targetValue'] as num).toInt(),
        targetUnit: json['targetUnit'] as String? ?? '',
        createdAt: json['createdAt'] as String,
        color: json['color'] as String,
        icon: json['icon'] as String,
        isArchived: json['isArchived'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'type': type,
        'timeOfDay': timeOfDay,
        'targetValue': targetValue,
        'targetUnit': targetUnit,
        'createdAt': createdAt,
        'color': color,
        'icon': icon,
        'isArchived': isArchived,
      };

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? type,
    String? timeOfDay,
    int? targetValue,
    String? targetUnit,
    String? createdAt,
    String? color,
    String? icon,
    bool? isArchived,
  }) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        type: type ?? this.type,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        targetValue: targetValue ?? this.targetValue,
        targetUnit: targetUnit ?? this.targetUnit,
        createdAt: createdAt ?? this.createdAt,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        isArchived: isArchived ?? this.isArchived,
      );
}
