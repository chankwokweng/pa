String getLocalDateString([DateTime? date]) {
  final d = date ?? DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

List<String> getLastNDays(int n) {
  final result = <String>[];
  for (int i = n - 1; i >= 0; i--) {
    result.add(getLocalDateString(DateTime.now().subtract(Duration(days: i))));
  }
  return result;
}

DateTime parseLocalDate(String dateStr) {
  final parts = dateStr.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

String formatDuration(int seconds) {
  if (seconds < 0) return '00:00';
  final hrs = seconds ~/ 3600;
  final mins = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  String pad(int n) => n.toString().padLeft(2, '0');
  if (hrs > 0) return '$hrs:${pad(mins)}:${pad(secs)}';
  return '${pad(mins)}:${pad(secs)}';
}

String formatHeaderDate(String dateStr) {
  final d = parseLocalDate(dateStr);
  const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  // DateTime weekday: 1=Mon..7=Sun
  final weekday = weekdays[d.weekday - 1];
  final month = months[d.month - 1];
  return '$weekday, $month ${d.day}';
}

String narrowWeekday(DateTime d) {
  const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return names[d.weekday - 1];
}
