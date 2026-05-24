import '../utils/date_utils.dart' show getLocalDateString;

class TodoItem {
  final String id;
  final String title;
  final String description;
  final String details;
  final String priority; // 'low' | 'medium' | 'high' | 'urgent'
  final String? dueDate; // YYYY-MM-DD
  final String status; // 'pending' | 'in_progress' | 'completed' | 'cancelled'
  final String? linkedHabitId;
  final String? category;
  final String createdAt;
  final String? completedAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.description = '',
    this.details = '',
    this.priority = 'medium',
    this.dueDate,
    this.status = 'pending',
    this.linkedHabitId,
    this.category,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'pending' || status == 'in_progress';

  bool get isOverdue {
    if (dueDate == null || !isActive) return false;
    return dueDate!.compareTo(getLocalDateString()) < 0;
  }

  bool get isDueToday => dueDate == getLocalDateString();

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        details: json['details'] as String? ?? '',
        priority: json['priority'] as String? ?? 'medium',
        dueDate: json['dueDate'] as String?,
        status: json['status'] as String? ?? 'pending',
        linkedHabitId: json['linkedHabitId'] as String?,
        category: json['category'] as String?,
        createdAt: json['createdAt'] as String,
        completedAt: json['completedAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'details': details,
        'priority': priority,
        'dueDate': dueDate,
        'status': status,
        'linkedHabitId': linkedHabitId,
        'category': category,
        'createdAt': createdAt,
        'completedAt': completedAt,
      };

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    String? details,
    String? priority,
    String? dueDate,
    String? status,
    String? linkedHabitId,
    String? category,
    String? createdAt,
    String? completedAt,
  }) =>
      TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        details: details ?? this.details,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        linkedHabitId: linkedHabitId ?? this.linkedHabitId,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
      );
}
