import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/badge_model.dart';
import 'date_utils.dart';

class StreakResult {
  final int current;
  final int longest;
  const StreakResult(this.current, this.longest);
}

StreakResult calculateStreak(String habitId, List<HabitLog> logs) {
  final completedDates = logs
      .where((l) => l.habitId == habitId && l.isCompleted)
      .map((l) => l.date)
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a)); // newest first

  if (completedDates.isEmpty) return const StreakResult(0, 0);

  final todayStr = getLocalDateString();
  final yesterdayStr = getLocalDateString(DateTime.now().subtract(const Duration(days: 1)));

  int currentStreak = 0;
  final hasToday = completedDates.contains(todayStr);
  final hasYesterday = completedDates.contains(yesterdayStr);

  if (hasToday || hasYesterday) {
    var checkDate = parseLocalDate(hasToday ? todayStr : yesterdayStr);
    while (true) {
      final s = getLocalDateString(checkDate);
      if (completedDates.contains(s)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
  }

  // Longest streak (oldest → newest)
  final sorted = [...completedDates]..sort((a, b) => a.compareTo(b));
  int longest = 1;
  int running = 1;
  for (int i = 1; i < sorted.length; i++) {
    final prev = parseLocalDate(sorted[i - 1]);
    final curr = parseLocalDate(sorted[i]);
    final diff = curr.difference(prev).inDays;
    if (diff == 1) {
      running++;
    } else if (diff > 1) {
      running = 1;
    }
    if (running > longest) longest = running;
  }
  if (currentStreak > longest) longest = currentStreak;

  return StreakResult(currentStreak, longest);
}

int completedCountByCategory(
    List<HabitLog> logs, List<Habit> habits, String categoryId) {
  final ids = habits.where((h) => h.category == categoryId).map((h) => h.id).toSet();
  return logs.where((l) => ids.contains(l.habitId) && l.isCompleted).length;
}

List<BadgeModel> checkBadges(
    List<Habit> habits, List<HabitLog> logs, List<BadgeModel> existing) {
  final totalCompleted = logs.where((l) => l.isCompleted).length;

  return existing.map((badge) {
    if (badge.isUnlocked) return badge;

    bool unlocked = false;

    if (badge.id == 'badge-first-step') {
      unlocked = totalCompleted >= 1;
    } else if (badge.id == 'badge-centurion') {
      unlocked = totalCompleted >= 25;
    } else if (badge.id == 'badge-mindful-master') {
      unlocked = completedCountByCategory(logs, habits, 'mind') >= 5;
    } else if (badge.id == 'badge-consistency-3') {
      unlocked = habits.any((h) => calculateStreak(h.id, logs).longest >= 3);
    } else if (badge.id == 'badge-consistency-7') {
      unlocked = habits.any((h) => calculateStreak(h.id, logs).longest >= 7);
    }

    if (unlocked) {
      return badge.copyWith(unlockedAt: DateTime.now().toIso8601String());
    }
    return badge;
  }).toList();
}
