import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/badge_model.dart';
import '../models/app_settings.dart';
import '../models/todo_item.dart';
import '../models/planner_event.dart';

const _kHabits = 'aurahabit_habits';
const _kLogs = 'aurahabit_logs';
const _kBadges = 'aurahabit_badges';
const _kSettings = 'aurahabit_settings';
const _kTodos = 'aurahabit_todos';
const _kPlannerEvents = 'aurahabit_planner_events';
const _kTodoCategories = 'aurahabit_todo_categories';

class StorageService {
  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHabits);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => Habit.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHabits, jsonEncode(habits.map((h) => h.toJson()).toList()));
  }

  Future<List<HabitLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLogs);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => HabitLog.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> saveLogs(List<HabitLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLogs, jsonEncode(logs.map((l) => l.toJson()).toList()));
  }

  Future<List<BadgeModel>> loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBadges);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => BadgeModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> saveBadges(List<BadgeModel> badges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBadges, jsonEncode(badges.map((b) => b.toJson()).toList()));
  }

  Future<AppSettings?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettings);
    if (raw == null) return null;
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  Future<List<TodoItem>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTodos);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => TodoItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> saveTodos(List<TodoItem> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTodos, jsonEncode(todos.map((t) => t.toJson()).toList()));
  }

  Future<List<PlannerEvent>> loadPlannerEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPlannerEvents);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => PlannerEvent.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> savePlannerEvents(List<PlannerEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPlannerEvents, jsonEncode(events.map((e) => e.toJson()).toList()));
  }

  Future<List<String>> loadTodoCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTodoCategories);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => e as String).toList();
  }

  Future<void> saveTodoCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTodoCategories, jsonEncode(categories));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHabits);
    await prefs.remove(_kLogs);
    await prefs.remove(_kBadges);
    await prefs.remove(_kSettings);
    await prefs.remove(_kTodos);
    await prefs.remove(_kPlannerEvents);
    await prefs.remove(_kTodoCategories);
  }
}
