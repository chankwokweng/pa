import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/planner_event.dart';
import '../models/todo_item.dart';
import '../services/firestore_service.dart';
import '../services/google_calendar_service.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';

class PlannerProvider extends ChangeNotifier {
  final _storage = StorageService();
  final _firestore = FirestoreService();
  final _calendarService = GoogleCalendarService();
  late final StreamSubscription<User?> _authSub;

  // --- Data ---
  List<TodoItem> todos = [];
  List<PlannerEvent> events = [];
  List<String> todoCategories = [];

  // --- Auth ---
  String? _uid;
  bool _loaded = false;

  // --- UI state ---
  String selectedDate = getLocalDateString();
  int plannerTabIndex = 0; // 0=calendar, 1=todos, 2=events
  String todoFilter = 'all'; // 'all'|'today'|'upcoming'|'completed'
  String? selectedTodoCategory;

  // --- Google Calendar ---
  bool isCalendarConnected = false;
  bool isSyncing = false;
  String? calendarSyncError;

  // --- Editing ---
  TodoItem? editingTodo;
  PlannerEvent? editingEvent;

  PlannerProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuth);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // --- Computed ---

  List<TodoItem> get filteredTodos {
    final today = getLocalDateString();
    var result = switch (todoFilter) {
      'today' => todos.where((t) => t.dueDate == today && t.isActive).toList(),
      'upcoming' => todos
          .where((t) =>
              t.isActive &&
              t.dueDate != null &&
              t.dueDate!.compareTo(today) > 0)
          .toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)),
      'completed' => todos.where((t) => t.isCompleted).toList(),
      _ => todos.where((t) => !t.isCancelled).toList(),
    };
    if (selectedTodoCategory != null) {
      result = result.where((t) => t.category == selectedTodoCategory).toList();
    }
    return result;
  }

  List<PlannerEvent> get upcomingEvents {
    final now = DateTime.now();
    return events
        .where((e) => DateTime.parse(e.startDateTime).isAfter(
            now.subtract(const Duration(hours: 1))))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  List<TodoItem> todosForDate(String dateStr) =>
      todos.where((t) => t.dueDate == dateStr && !t.isCancelled).toList();

  List<PlannerEvent> eventsForDate(String dateStr) =>
      events.where((e) => e.startDateStr == dateStr).toList();

  // --- Auth ---

  Future<void> _onAuth(User? user) async {
    _uid = user?.uid;
    if (user != null && !_loaded) {
      _loaded = true;
      await _loadLocal();
      await _syncFromFirestore(user.uid);
      await _calendarService.tryRestoreConnection().then((connected) {
        isCalendarConnected = connected;
        notifyListeners();
      });
    } else if (user == null) {
      todos = [];
      events = [];
      todoCategories = [];
      selectedTodoCategory = null;
      _loaded = false;
      isCalendarConnected = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocal() async {
    todos = await _storage.loadTodos();
    events = await _storage.loadPlannerEvents();
    todoCategories = await _storage.loadTodoCategories();
    notifyListeners();
  }

  Future<void> _syncFromFirestore(String uid) async {
    try {
      final remoteTodos = await _firestore.loadTodos(uid);
      final remoteEvents = await _firestore.loadPlannerEvents(uid);
      if (remoteTodos.isNotEmpty || remoteEvents.isNotEmpty) {
        todos = remoteTodos;
        events = remoteEvents;
        await _storage.saveTodos(todos);
        await _storage.savePlannerEvents(events);
        notifyListeners();
      }
    } catch (_) {
      // continue with local data on network failure
    }
  }

  // --- Todo actions ---

  void createOrUpdateTodo({
    required String title,
    required String description,
    required String details,
    required String priority,
    String? dueDate,
    required String status,
    String? linkedHabitId,
    String? category,
  }) {
    // Auto-register new categories
    if (category != null && !todoCategories.contains(category)) {
      todoCategories = [...todoCategories, category];
      _storage.saveTodoCategories(todoCategories);
    }

    if (editingTodo != null) {
      final updated = TodoItem(
        id: editingTodo!.id,
        title: title,
        description: description,
        details: details,
        priority: priority,
        dueDate: dueDate,
        status: status,
        linkedHabitId: linkedHabitId,
        category: category,
        createdAt: editingTodo!.createdAt,
        completedAt: status == 'completed'
            ? (editingTodo!.completedAt ?? DateTime.now().toIso8601String())
            : null,
      );
      final nextTodos = todos.map((t) => t.id == updated.id ? updated : t).toList();
      _saveTodos(nextTodos, updated);
      editingTodo = null;
    } else {
      final newTodo = TodoItem(
        id: 'todo-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        details: details,
        priority: priority,
        dueDate: dueDate,
        status: status,
        linkedHabitId: linkedHabitId,
        category: category,
        createdAt: DateTime.now().toIso8601String(),
        completedAt: status == 'completed' ? DateTime.now().toIso8601String() : null,
      );
      _saveTodos([...todos, newTodo], newTodo);
    }
    notifyListeners();
  }

  void quickCompleteTodo(String id) {
    final idx = todos.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final updated = TodoItem(
      id: todos[idx].id,
      title: todos[idx].title,
      description: todos[idx].description,
      details: todos[idx].details,
      priority: todos[idx].priority,
      dueDate: todos[idx].dueDate,
      status: todos[idx].isCompleted ? 'pending' : 'completed',
      linkedHabitId: todos[idx].linkedHabitId,
      createdAt: todos[idx].createdAt,
      completedAt: todos[idx].isCompleted ? null : DateTime.now().toIso8601String(),
    );
    final next = [...todos];
    next[idx] = updated;
    _saveTodos(next, updated);
  }

  void deleteTodo(String id) {
    final next = todos.where((t) => t.id != id).toList();
    todos = next;
    _storage.saveTodos(todos);
    if (_uid != null) {
      _firestore.deleteTodo(_uid!, id).catchError((_) {});
    }
    notifyListeners();
  }

  void openEditTodo(TodoItem todo) {
    editingTodo = todo;
    notifyListeners();
  }

  void clearEditingTodo() {
    editingTodo = null;
    notifyListeners();
  }

  // --- Event actions ---

  Future<void> createOrUpdateEvent({
    required String title,
    required String description,
    required String location,
    required String startDateTime,
    String? endDateTime,
    required bool isAllDay,
    required String color,
    required bool syncToGoogle,
  }) async {
    if (editingEvent != null) {
      var updated = PlannerEvent(
        id: editingEvent!.id,
        googleEventId: editingEvent!.googleEventId,
        title: title,
        description: description,
        location: location,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        isAllDay: isAllDay,
        color: color,
        isSynced: editingEvent!.isSynced,
        createdAt: editingEvent!.createdAt,
      );

      if (syncToGoogle && isCalendarConnected) {
        if (updated.googleEventId != null) {
          await _calendarService.updateEvent(updated);
        } else {
          final gId = await _calendarService.createEvent(updated);
          if (gId != null) {
            updated = PlannerEvent(
              id: updated.id,
              googleEventId: gId,
              title: updated.title,
              description: updated.description,
              location: updated.location,
              startDateTime: updated.startDateTime,
              endDateTime: updated.endDateTime,
              isAllDay: updated.isAllDay,
              color: updated.color,
              isSynced: true,
              createdAt: updated.createdAt,
            );
          }
        }
      }

      final next = events.map((e) => e.id == updated.id ? updated : e).toList();
      _saveEvents(next, updated);
      editingEvent = null;
    } else {
      var newEvent = PlannerEvent(
        id: 'event-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        location: location,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        isAllDay: isAllDay,
        color: color,
        isSynced: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (syncToGoogle && isCalendarConnected) {
        final gId = await _calendarService.createEvent(newEvent);
        if (gId != null) {
          newEvent = PlannerEvent(
            id: newEvent.id,
            googleEventId: gId,
            title: newEvent.title,
            description: newEvent.description,
            location: newEvent.location,
            startDateTime: newEvent.startDateTime,
            endDateTime: newEvent.endDateTime,
            isAllDay: newEvent.isAllDay,
            color: newEvent.color,
            isSynced: true,
            createdAt: newEvent.createdAt,
          );
        }
      }

      _saveEvents([...events, newEvent], newEvent);
    }
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    final event = events.firstWhere((e) => e.id == id,
        orElse: () => const PlannerEvent(
            id: '', title: '', startDateTime: '', createdAt: ''));
    if (event.googleEventId != null) {
      await _calendarService.deleteEvent(event.googleEventId!).catchError((_) => false);
    }
    events = events.where((e) => e.id != id).toList();
    _storage.savePlannerEvents(events);
    if (_uid != null) {
      _firestore.deletePlannerEvent(_uid!, id).catchError((_) {});
    }
    notifyListeners();
  }

  void openEditEvent(PlannerEvent event) {
    editingEvent = event;
    notifyListeners();
  }

  void clearEditingEvent() {
    editingEvent = null;
    notifyListeners();
  }

  // --- Google Calendar sync ---

  Future<bool> connectGoogleCalendar() async {
    final success = await _calendarService.connect();
    isCalendarConnected = success;
    if (success) await syncFromGoogleCalendar();
    notifyListeners();
    return success;
  }

  Future<void> disconnectGoogleCalendar() async {
    await _calendarService.disconnect();
    isCalendarConnected = false;
    notifyListeners();
  }

  Future<void> syncFromGoogleCalendar() async {
    if (!isCalendarConnected) return;
    isSyncing = true;
    calendarSyncError = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final fetched = await _calendarService.fetchEvents(
        timeMin: now.subtract(const Duration(days: 30)),
        timeMax: now.add(const Duration(days: 90)),
      );

      // Merge: keep local-only events, replace synced ones from Google
      final localOnly = events.where((e) => !e.isSynced).toList();
      final merged = [...localOnly, ...fetched];
      events = merged;
      await _storage.savePlannerEvents(events);

      // Persist synced events to Firestore
      if (_uid != null) {
        for (final e in fetched) {
          _firestore.savePlannerEvent(_uid!, e).catchError((_) {});
        }
      }
    } catch (e) {
      calendarSyncError = 'Sync failed. Please try again.';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  // --- UI state ---

  void setSelectedDate(String date) {
    selectedDate = date;
    notifyListeners();
  }

  void setPlannerTab(int index) {
    plannerTabIndex = index;
    notifyListeners();
  }

  void setTodoFilter(String filter) {
    todoFilter = filter;
    notifyListeners();
  }

  void setTodoCategory(String? category) {
    selectedTodoCategory = category;
    notifyListeners();
  }

  // --- Internal helpers ---

  void _saveTodos(List<TodoItem> next, TodoItem changed) {
    todos = next;
    _storage.saveTodos(todos);
    if (_uid != null) {
      _firestore.saveTodo(_uid!, changed).catchError((_) {});
    }
    notifyListeners();
  }

  void _saveEvents(List<PlannerEvent> next, PlannerEvent changed) {
    events = next;
    _storage.savePlannerEvents(events);
    if (_uid != null) {
      _firestore.savePlannerEvent(_uid!, changed).catchError((_) {});
    }
    notifyListeners();
  }
}
