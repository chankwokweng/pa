class HabitLog {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD
  final int value;
  final int targetValue;
  final bool isCompleted;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.value,
    required this.targetValue,
    required this.isCompleted,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
        id: json['id'] as String,
        habitId: json['habitId'] as String,
        date: json['date'] as String,
        value: (json['value'] as num).toInt(),
        targetValue: (json['targetValue'] as num).toInt(),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'date': date,
        'value': value,
        'targetValue': targetValue,
        'isCompleted': isCompleted,
      };

  HabitLog copyWith({
    String? id,
    String? habitId,
    String? date,
    int? value,
    int? targetValue,
    bool? isCompleted,
  }) =>
      HabitLog(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        date: date ?? this.date,
        value: value ?? this.value,
        targetValue: targetValue ?? this.targetValue,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}
