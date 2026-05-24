import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/badge_model.dart';
import '../providers/app_provider.dart';
import '../utils/badge_checker.dart';
import '../utils/color_map.dart';
import '../utils/date_utils.dart';
import '../utils/icon_map.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final habits = provider.habits;
    final logs = provider.logs;
    final badges = provider.badges;
    final active = habits.where((h) => !h.isArchived).toList();

    final today = getLocalDateString();
    final completedToday = logs.where((l) => l.date == today && l.isCompleted).length;
    final totalCompleted = logs.where((l) => l.isCompleted).length;
    final completionRate = active.isEmpty ? 0 : (completedToday * 100 ~/ active.length);

    int maxCurrent = 0;
    int maxLongest = 0;
    for (final h in active) {
      final s = calculateStreak(h.id, logs);
      if (s.current > maxCurrent) maxCurrent = s.current;
      if (s.longest > maxLongest) maxLongest = s.longest;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        const Text('Analytics & Achievements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text('Track milestones, streaks, and consistency',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        const SizedBox(height: 16),

        // Stat cards
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF6366F1),
              value: '$completionRate%',
              label: 'Today\'s Rate',
            ),
            _StatCard(
              icon: Icons.done_all,
              iconColor: Colors.green.shade500,
              value: '$totalCompleted',
              label: 'Total Check-ins',
            ),
            _StatCard(
              icon: Icons.local_fire_department,
              iconColor: Colors.amber.shade500,
              value: '$maxCurrent',
              label: 'Current Streak',
            ),
            _StatCard(
              icon: Icons.emoji_events,
              iconColor: Colors.orange.shade400,
              value: '$maxLongest',
              label: 'Longest Streak',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Category breakdown
        const Text('BY CATEGORY',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.grey)),
        const SizedBox(height: 10),
        ...kCategorySpecs.entries.map((entry) {
          final catId = entry.key;
          final spec = entry.value;
          final catHabits = habits.where((h) => h.category == catId && !h.isArchived).toList();
          if (catHabits.isEmpty) return const SizedBox.shrink();

          final last30 = getLastNDays(30);
          int possible = 0;
          int done = 0;
          for (final d in last30) {
            for (final h in catHabits) {
              possible++;
              if (logs.any((l) => l.habitId == h.id && l.date == d && l.isCompleted)) done++;
            }
          }
          final pct = possible > 0 ? done * 100 ~/ possible : 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: spec.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconFor(spec.icon), size: 18, color: spec.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spec.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(spec.color),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('$pct%',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // 56-day heatmap
        const Text('8-WEEK HEATMAP',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.grey)),
        const SizedBox(height: 10),
        _Heatmap(habits: habits.where((h) => !h.isArchived).toList(), logs: logs),

        const SizedBox(height: 20),

        // Badges
        const Text('BADGES',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.grey)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: badges.map((b) => _BadgeCard(badge: b)).toList(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? Colors.green.shade50
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: unlocked
                ? Colors.green.shade100
                : Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconFor(badge.icon),
            size: 24,
            color: unlocked ? Colors.green.shade500 : Colors.grey.shade300,
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: unlocked ? Colors.grey.shade800 : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            badge.requirementText,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final List habits;
  final List logs;

  const _Heatmap({required this.habits, required this.logs});

  @override
  Widget build(BuildContext context) {
    final days = getLastNDays(56);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final d = days[i];
        final habitsOnDay = habits.where((h) {
          final created = (h.createdAt as String).split('T')[0];
          return created.compareTo(d) <= 0;
        }).toList();
        final done = logs.where((l) {
          return l.date == d &&
              l.isCompleted &&
              habitsOnDay.any((h) => h.id == l.habitId);
        }).length;
        final possible = habitsOnDay.length;
        final ratio = possible > 0 ? done / possible : 0.0;

        Color cellColor;
        if (ratio == 0) {
          cellColor = Colors.grey.shade100;
        } else if (ratio <= 0.3) {
          cellColor = Colors.green.shade100;
        } else if (ratio <= 0.65) {
          cellColor = Colors.green.shade300;
        } else if (ratio <= 0.9) {
          cellColor = Colors.green.shade500;
        } else {
          cellColor = Colors.green.shade700;
        }

        return Tooltip(
          message: '$d: $done/$possible',
          child: Container(
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }
}
