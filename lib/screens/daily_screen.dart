import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/habit_card.dart';
import '../utils/badge_checker.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = provider.filteredHabits;
    final quote = kMotivationalQuotes[provider.quoteIndex];
    final headerDate = formatHeaderDate(provider.selectedDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // Quote banner
        if (provider.settings.showQuote) ...[
          _QuoteBanner(quote: quote, onDismiss: provider.dismissQuote),
          const SizedBox(height: 16),
        ],

        // Calendar header card
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerDate,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Tap a day below to back-register habits',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  _TimeFilter(
                    selected: provider.selectedTimeOfDay,
                    onSelect: provider.setTimeOfDay,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const CalendarStrip(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Habits header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MY DAILY HABITS (${filtered.length})',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade400,
                letterSpacing: 1,
              ),
            ),
            GestureDetector(
              onTap: provider.openCreateForm,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Color(0xFF6366F1)),
                    SizedBox(width: 4),
                    Text(
                      'Quick Add',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Habits grid
        if (filtered.isEmpty)
          _EmptyState(onAdd: provider.openCreateForm)
        else
          ...filtered.map((h) {
            final log = provider.logFor(h.id);
            final streak = calculateStreak(h.id, provider.logs).current;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HabitCard(habit: h, log: log, currentStreak: streak),
            );
          }),
      ],
    );
  }
}

class _QuoteBanner extends StatelessWidget {
  final Map<String, String> quote;
  final VoidCallback onDismiss;

  const _QuoteBanner({required this.quote, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ATOMIC INSIGHT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6366F1),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${quote['text']}"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '— ${quote['author']}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _TimeFilter extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _TimeFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('all', 'All'),
      ('morning', 'AM'),
      ('afternoon', 'PM'),
      ('evening', 'Eve'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map(((String, String) opt) {
          final isSelected = selected == opt.$1;
          return GestureDetector(
            onTap: () => onSelect(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                    : null,
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.grey.shade900 : Colors.grey.shade500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.explore, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No Habits for This Day',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Add habits to begin tracking your daily routine.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Form Your First Habit'),
          ),
        ],
      ),
    );
  }
}
