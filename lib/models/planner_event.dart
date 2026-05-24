class PlannerEvent {
  final String id;
  final String? googleEventId;
  final String title;
  final String description;
  final String location;
  final String startDateTime; // ISO 8601
  final String? endDateTime; // ISO 8601
  final bool isAllDay;
  final String color; // 'blue'|'green'|'red'|'orange'|'purple'|'teal'
  final bool isSynced;
  final String createdAt;

  const PlannerEvent({
    required this.id,
    this.googleEventId,
    required this.title,
    this.description = '',
    this.location = '',
    required this.startDateTime,
    this.endDateTime,
    this.isAllDay = false,
    this.color = 'blue',
    this.isSynced = false,
    required this.createdAt,
  });

  String get startDateStr => startDateTime.split('T')[0];

  DateTime get startDateLocal => DateTime.parse(startDateTime).toLocal();

  DateTime? get endDateLocal =>
      endDateTime != null ? DateTime.parse(endDateTime!).toLocal() : null;

  factory PlannerEvent.fromJson(Map<String, dynamic> json) => PlannerEvent(
        id: json['id'] as String,
        googleEventId: json['googleEventId'] as String?,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        location: json['location'] as String? ?? '',
        startDateTime: json['startDateTime'] as String,
        endDateTime: json['endDateTime'] as String?,
        isAllDay: json['isAllDay'] as bool? ?? false,
        color: json['color'] as String? ?? 'blue',
        isSynced: json['isSynced'] as bool? ?? false,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'googleEventId': googleEventId,
        'title': title,
        'description': description,
        'location': location,
        'startDateTime': startDateTime,
        'endDateTime': endDateTime,
        'isAllDay': isAllDay,
        'color': color,
        'isSynced': isSynced,
        'createdAt': createdAt,
      };

  PlannerEvent copyWith({
    String? id,
    String? googleEventId,
    String? title,
    String? description,
    String? location,
    String? startDateTime,
    String? endDateTime,
    bool? isAllDay,
    String? color,
    bool? isSynced,
    String? createdAt,
  }) =>
      PlannerEvent(
        id: id ?? this.id,
        googleEventId: googleEventId ?? this.googleEventId,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        startDateTime: startDateTime ?? this.startDateTime,
        endDateTime: endDateTime ?? this.endDateTime,
        isAllDay: isAllDay ?? this.isAllDay,
        color: color ?? this.color,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
      );
}
