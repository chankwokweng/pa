class AppSettings {
  final String userName;
  final String avatarSeed;
  final bool showQuote;
  final String themeColor;
  final bool notificationsEnabled;

  const AppSettings({
    required this.userName,
    required this.avatarSeed,
    required this.showQuote,
    required this.themeColor,
    required this.notificationsEnabled,
  });

  factory AppSettings.defaults() => const AppSettings(
        userName: 'Aura Achiever',
        avatarSeed: 'avatar-1',
        showQuote: true,
        themeColor: 'indigo',
        notificationsEnabled: false,
      );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        userName: json['userName'] as String? ?? 'Aura Achiever',
        avatarSeed: json['avatarSeed'] as String? ?? 'avatar-1',
        showQuote: json['showQuote'] as bool? ?? true,
        themeColor: json['themeColor'] as String? ?? 'indigo',
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'avatarSeed': avatarSeed,
        'showQuote': showQuote,
        'themeColor': themeColor,
        'notificationsEnabled': notificationsEnabled,
      };

  AppSettings copyWith({
    String? userName,
    String? avatarSeed,
    bool? showQuote,
    String? themeColor,
    bool? notificationsEnabled,
  }) =>
      AppSettings(
        userName: userName ?? this.userName,
        avatarSeed: avatarSeed ?? this.avatarSeed,
        showQuote: showQuote ?? this.showQuote,
        themeColor: themeColor ?? this.themeColor,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}
