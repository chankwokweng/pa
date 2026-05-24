import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/planner_event.dart';
import '../../models/todo_item.dart';
import '../../providers/app_provider.dart';
import '../../providers/planner_provider.dart';

// Marker types encoded as simple strings for the event loader
const _kEvent = 'event';
const _kTodo = 'todo';
const _kHabit = 'habit';

class PlannerCalendar extends StatefulWidget {
  const PlannerCalendar({super.key});

  @override
  State<PlannerCalendar> createState() => _PlannerCalendarState();
}

class _PlannerCalendarState extends State<PlannerCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
            planner.setSelectedDate(
              '${selected.year.toString().padLeft(4, '0')}-'
              '${selected.month.toString().padLeft(2, '0')}-'
              '${selected.day.toString().padLeft(2, '0')}',
            );
          },
          onPageChanged: (focused) => setState(() => _focusedDay = focused),
          eventLoader: (day) => _markersFor(day, planner, app),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, markers) {
              if (markers.isEmpty) return null;
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: markers.map((m) {
                    final color = switch (m) {
                      _kEvent => const Color(0xFF3B82F6),
                      _kTodo => const Color(0xFFF97316),
                      _ => const Color(0xFF10B981),
                    };
                    return Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w700),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            todayTextStyle:
                const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
            markersAlignment: Alignment.bottomCenter,
          ),
        ),
        const Divider(height: 1),
        _DayDetail(
          dateStr: planner.selectedDate,
          todos: planner.todosForDate(planner.selectedDate),
          events: planner.eventsForDate(planner.selectedDate),
        ),
      ],
    );
  }

  List<Object> _markersFor(DateTime day, PlannerProvider planner, AppProvider app) {
    final dateStr = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';

    final markers = <Object>[];

    if (planner.events.any((e) => e.startDateStr == dateStr)) {
      markers.add(_kEvent);
    }
    if (planner.todos.any((t) => t.dueDate == dateStr && !t.isCancelled)) {
      markers.add(_kTodo);
    }

    final habitsOnDay = app.habits.where((h) {
      final created = h.createdAt.split('T')[0];
      return created.compareTo(dateStr) <= 0 && !h.isArchived;
    }).toList();
    if (habitsOnDay.isNotEmpty) {
      final completed = app.logs.where((l) =>
          l.date == dateStr &&
          habitsOnDay.any((h) => h.id == l.habitId) &&
          l.isCompleted).length;
      if (completed > 0) markers.add(_kHabit);
    }

    return markers;
  }
}

class _DayDetail extends StatelessWidget {
  final String dateStr;
  final List<TodoItem> todos;
  final List<PlannerEvent> events;

  const _DayDetail({
    required this.dateStr,
    required this.todos,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = DateTime.tryParse(dateStr);
    final title = dt != null
        ? DateFormat('EEEE, MMMM d').format(dt)
        : dateStr;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (todos.isEmpty && events.isEmpty)
            Expanded(
              child: Center(
                child: Text('Nothing scheduled',
                    style: TextStyle(color: Colors.grey.shade400)),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (events.isNotEmpty) ...[
                    _sectionLabel('Events', const Color(0xFF3B82F6)),
                    ...events.map((e) => _EventTile(event: e)),
                    const SizedBox(height: 8),
                  ],
                  if (todos.isNotEmpty) ...[
                    _sectionLabel('To-Dos', const Color(0xFFF97316)),
                    ...todos.map((t) => _TodoTile(todo: t)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5)),
          ],
        ),
      );
}

class _EventTile extends StatelessWidget {
  final PlannerEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final planner = context.read<PlannerProvider>();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event, size: 18, color: Color(0xFF3B82F6)),
      title: Text(event.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: event.location.isNotEmpty
          ? Text(event.location,
              style:
                  const TextStyle(fontSize: 11, color: Colors.grey))
          : null,
      onTap: () {
        planner.openEditEvent(event);
        // The PlannerScreen listens for editingEvent changes
      },
    );
  }
}

class _TodoTile extends StatelessWidget {
  final TodoItem todo;
  const _TodoTile({required this.todo});

  @override
  Widget build(BuildContext context) {
    final planner = context.read<PlannerProvider>();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: GestureDetector(
        onTap: () => planner.quickCompleteTodo(todo.id),
        child: Icon(
          todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: todo.isCompleted ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          decoration:
              todo.isCompleted ? TextDecoration.lineThrough : null,
          color: todo.isCompleted ? Colors.grey : null,
        ),
      ),
      onTap: () => planner.openEditTodo(todo),
    );
  }
}
