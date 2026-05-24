import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/planner_provider.dart';
import '../widgets/planner/event_card.dart';
import '../widgets/planner/event_form_sheet.dart';
import '../widgets/planner/planner_calendar.dart';
import '../widgets/planner/todo_card.dart';
import '../widgets/planner/todo_form_sheet.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<PlannerProvider>().setPlannerTab(_tabCtrl.index);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // Watch for planner.editingTodo / editingEvent changes and show form sheets
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowSheets());
  }

  void _maybeShowSheets() {
    final planner = context.read<PlannerProvider>();
    if (planner.editingTodo != null && mounted) {
      _openTodoSheet();
    } else if (planner.editingEvent != null && mounted) {
      _openEventSheet();
    }
  }

  Future<void> _openTodoSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PlannerProvider>(),
        child: const TodoFormSheet(),
      ),
    );
    if (mounted) context.read<PlannerProvider>().clearEditingTodo();
  }

  Future<void> _openEventSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PlannerProvider>(),
        child: const EventFormSheet(),
      ),
    );
    if (mounted) context.read<PlannerProvider>().clearEditingEvent();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();

    // React to sheet triggers after each rebuild
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeShowSheets());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (planner.isCalendarConnected)
            IconButton(
              icon: planner.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sync Google Calendar',
              onPressed:
                  planner.isSyncing ? null : planner.syncFromGoogleCalendar,
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Calendar'),
            Tab(icon: Icon(Icons.checklist), text: 'To-Dos'),
            Tab(icon: Icon(Icons.event_outlined), text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 0: Calendar
          const PlannerCalendar(),

          // Tab 1: Todos
          _TodosTab(
            onAdd: () {
              planner.clearEditingTodo();
              _openTodoSheet();
            },
          ),

          // Tab 2: Events
          _EventsTab(
            onAdd: () {
              planner.clearEditingEvent();
              _openEventSheet();
            },
          ),
        ],
      ),
      floatingActionButton: _buildFab(planner),
    );
  }

  Widget? _buildFab(PlannerProvider planner) {
    final tabIndex = _tabCtrl.index;
    if (tabIndex == 1) {
      return FloatingActionButton(
        heroTag: 'fab_todo',
        onPressed: () {
          planner.clearEditingTodo();
          _openTodoSheet();
        },
        child: const Icon(Icons.add),
      );
    }
    if (tabIndex == 2) {
      return FloatingActionButton(
        heroTag: 'fab_event',
        onPressed: () {
          planner.clearEditingEvent();
          _openEventSheet();
        },
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
}

// ─── Todos tab ───────────────────────────────────────────────────────────────

class _TodosTab extends StatelessWidget {
  final VoidCallback onAdd;
  const _TodosTab({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final todos = planner.filteredTodos;

    return Column(
      children: [
        // Status filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _FilterChip(label: 'All', value: 'all', planner: planner),
              _FilterChip(label: 'Today', value: 'today', planner: planner),
              _FilterChip(
                  label: 'Upcoming', value: 'upcoming', planner: planner),
              _FilterChip(
                  label: 'Completed', value: 'completed', planner: planner),
            ],
          ),
        ),
        // Category filter chips (only shown when categories exist)
        if (planner.todoCategories.isNotEmpty) ...[
          const Divider(height: 1),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _CategoryChip(label: 'All', value: null, planner: planner),
                ...planner.todoCategories.map((cat) =>
                    _CategoryChip(label: cat, value: cat, planner: planner)),
              ],
            ),
          ),
        ],
        const Divider(height: 1),
        if (todos.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('No to-dos yet',
                      style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add To-Do'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: todos.length,
              itemBuilder: (_, i) {
                final todo = todos[i];
                return TodoCard(
                  todo: todo,
                  onToggle: () => planner.quickCompleteTodo(todo.id),
                  onEdit: () => planner.openEditTodo(todo),
                  onDelete: () => _confirmDelete(context, planner, todo.id),
                );
              },
            ),
          ),
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, PlannerProvider planner, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete To-Do'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              planner.deleteTodo(id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final PlannerProvider planner;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.planner,
  });

  @override
  Widget build(BuildContext context) {
    final active = planner.todoFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => planner.setTodoFilter(value),
        showCheckmark: false,
        selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: active ? const Color(0xFF6366F1) : null,
          fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String? value;
  final PlannerProvider planner;

  const _CategoryChip({
    required this.label,
    required this.value,
    required this.planner,
  });

  @override
  Widget build(BuildContext context) {
    final active = planner.selectedTodoCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => planner.setTodoCategory(value),
        showCheckmark: false,
        selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: active ? const Color(0xFF6366F1) : null,
          fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── Events tab ──────────────────────────────────────────────────────────────

class _EventsTab extends StatelessWidget {
  final VoidCallback onAdd;
  const _EventsTab({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final events = planner.upcomingEvents;

    return Column(
      children: [
        // Google Calendar connection banner
        if (!planner.isCalendarConnected)
          _CalendarConnectBanner(planner: planner),

        if (planner.calendarSyncError != null)
          _ErrorBanner(message: planner.calendarSyncError!),

        if (events.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('No upcoming events',
                      style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Event'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: events.length,
              itemBuilder: (_, i) {
                final event = events[i];
                return EventCard(
                  event: event,
                  onEdit: () => planner.openEditEvent(event),
                  onDelete: () =>
                      _confirmDelete(context, planner, event.id),
                );
              },
            ),
          ),
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, PlannerProvider planner, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event'),
        content: const Text(
            'This will also remove it from Google Calendar if synced.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              planner.deleteEvent(id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CalendarConnectBanner extends StatelessWidget {
  final PlannerProvider planner;
  const _CalendarConnectBanner({required this.planner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month,
              color: Color(0xFF6366F1), size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connect Google Calendar',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1))),
                Text('Sync events with your Google Calendar',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          FilledButton(
            onPressed: planner.connectGoogleCalendar,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }
}
