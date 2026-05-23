import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/badge_model.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/badge_checker.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class CalendarDay {
  final String date;
  final String dayName;
  final int dayNum;
  final bool isToday;
  final bool isSelected;
  final double completionRatio;

  const CalendarDay({
    required this.date,
    required this.dayName,
    required this.dayNum,
    required this.isToday,
    required this.isSelected,
    required this.completionRatio,
  });
}

class AppProvider extends ChangeNotifier {
  final _storage = StorageService();
  final _firestore = FirestoreService();
  late final StreamSubscription<User?> _authSub;

  // --- State ---
  List<Habit> habits = [];
  List<HabitLog> logs = [];
  List<BadgeModel> badges = [];
  AppSettings settings = AppSettings.defaults();

  User? user;
  bool authLoading = true;

  int activeTabIndex = 0; // 0=daily, 1=habits, 2=stats, 3=settings
  String selectedDate = getLocalDateString();
  String selectedTimeOfDay = 'all';
  bool isFormOpen = false;
  Habit? editingHabit;
  BadgeModel? unlockedBadgeToast;
  String? archiveHabitId;
  int quoteIndex = 0;
  bool _dataLoaded = false;

  AppProvider() {
    quoteIndex = Random().nextInt(kMotivationalQuotes.length);
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuth);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // --- Computed ---

  List<Habit> get filteredHabits {
    return habits.where((h) {
      if (h.isArchived) return false;
      final createdDate = h.createdAt.split('T')[0];
      if (createdDate.compareTo(selectedDate) > 0) return false;
      if (selectedTimeOfDay != 'all' && h.timeOfDay != selectedTimeOfDay) return false;
      return true;
    }).toList();
  }

  List<CalendarDay> get calendarDays {
    final dates = getLastNDays(7);
    final todayStr = getLocalDateString();
    return dates.map((d) {
      final dt = parseLocalDate(d);
      final habitsOnDay = habits.where((h) {
        final created = h.createdAt.split('T')[0];
        return created.compareTo(d) <= 0 && !h.isArchived;
      }).toList();
      final dayLogs = logs.where((l) => l.date == d).toList();
      final completed = dayLogs.where((l) {
        return habitsOnDay.any((h) => h.id == l.habitId) && l.isCompleted;
      }).length;
      final ratio = habitsOnDay.isEmpty ? 0.0 : completed / habitsOnDay.length;
      return CalendarDay(
        date: d,
        dayName: narrowWeekday(dt),
        dayNum: dt.day,
        isToday: d == todayStr,
        isSelected: d == selectedDate,
        completionRatio: ratio,
      );
    }).toList();
  }

  HabitLog? logFor(String habitId) =>
      logs.where((l) => l.habitId == habitId && l.date == selectedDate).firstOrNull;

  // --- Auth ---

  Future<void> _onAuth(User? u) async {
    user = u;
    authLoading = false;
    notifyListeners();
    if (u != null) {
      if (!_dataLoaded) await _loadLocal();
      await _syncFromFirestore(u.uid);
    }
  }

  Future<void> signIn() async {
    try {
      final provider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithPopup(provider);
    } catch (e) {
      // auth/popup-closed-by-user is not an error
      if (e is FirebaseAuthException &&
          (e.code == 'popup-closed-by-user' ||
              e.code == 'cancelled-popup-request')) {
        return;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // --- Local load ---

  Future<void> _loadLocal() async {
    _dataLoaded = true;
    final localHabits = await _storage.loadHabits();
    final localLogs = await _storage.loadLogs();
    final localBadges = await _storage.loadBadges();
    final localSettings = await _storage.loadSettings();

    habits = localHabits.isNotEmpty ? localHabits : getInitialHabits();
    logs = localLogs;
    badges = localBadges.isNotEmpty ? localBadges : List.from(kDefaultBadges);
    settings = localSettings ?? AppSettings.defaults();

    if (localHabits.isEmpty) await _storage.saveHabits(habits);
    if (localBadges.isEmpty) await _storage.saveBadges(badges);

    notifyListeners();
  }

  // --- Firestore sync ---

  Future<void> _syncFromFirestore(String uid) async {
    try {
      final data = await _firestore.loadUserData(uid);
      if (data.habits.isNotEmpty) {
        habits = data.habits;
        logs = data.logs;
        badges = data.badges.isNotEmpty ? data.badges : List.from(kDefaultBadges);
        if (data.settings != null) settings = data.settings!;
        await _storage.saveHabits(habits);
        await _storage.saveLogs(logs);
        await _storage.saveBadges(badges);
        await _storage.saveSettings(settings);
      } else {
        // First login — migrate local data to Firestore
        await _firestore.saveAllData(uid, habits, logs, badges);
        await _firestore.saveUserSettings(uid, settings);
      }
      notifyListeners();
    } catch (e) {
      // Network failure — continue with local data
    }
  }

  // --- Habit actions ---

  void updateProgress(String habitId, int newValue) {
    final habit = habits.firstWhere((h) => h.id == habitId);
    final isCompleted = newValue >= habit.targetValue;
    final idx = logs.indexWhere((l) => l.habitId == habitId && l.date == selectedDate);

    HabitLog changedLog;
    final nextLogs = [...logs];

    if (idx >= 0) {
      changedLog = nextLogs[idx].copyWith(value: newValue, isCompleted: isCompleted);
      nextLogs[idx] = changedLog;
    } else {
      changedLog = HabitLog(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}',
        habitId: habitId,
        date: selectedDate,
        value: newValue,
        targetValue: habit.targetValue,
        isCompleted: isCompleted,
      );
      nextLogs.add(changedLog);
    }

    _saveLogs(nextLogs, changedLog);
  }

  void createOrUpdateHabit({
    required String name,
    required String description,
    required String category,
    required String type,
    required String timeOfDay,
    required int targetValue,
    required String targetUnit,
    required String color,
    required String icon,
  }) {
    if (editingHabit != null) {
      final updated = editingHabit!.copyWith(
        name: name,
        description: description,
        category: category,
        type: type,
        timeOfDay: timeOfDay,
        targetValue: targetValue,
        targetUnit: targetUnit,
        color: color,
        icon: icon,
      );
      final nextHabits = habits.map((h) => h.id == updated.id ? updated : h).toList();
      _saveHabits(nextHabits, updated);
      editingHabit = null;
    } else {
      final newHabit = Habit(
        id: 'habit-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        category: category,
        type: type,
        timeOfDay: timeOfDay,
        targetValue: targetValue,
        targetUnit: targetUnit,
        createdAt: DateTime.now().toIso8601String(),
        color: color,
        icon: icon,
        isArchived: false,
      );
      _saveHabits([...habits, newHabit], newHabit);
    }
    isFormOpen = false;
    notifyListeners();
  }

  void requestArchive(String habitId) {
    archiveHabitId = habitId;
    notifyListeners();
  }

  void confirmArchive() {
    if (archiveHabitId == null) return;
    final archived = habits.firstWhere((h) => h.id == archiveHabitId!);
    final updated = archived.copyWith(isArchived: true);
    final nextHabits = habits.map((h) => h.id == archiveHabitId ? updated : h).toList();
    _saveHabits(nextHabits, updated);
    archiveHabitId = null;
    notifyListeners();
  }

  void cancelArchive() {
    archiveHabitId = null;
    notifyListeners();
  }

  void openEditForm(Habit habit) {
    editingHabit = habit;
    isFormOpen = true;
    notifyListeners();
  }

  void openCreateForm() {
    editingHabit = null;
    isFormOpen = true;
    notifyListeners();
  }

  void closeForm() {
    isFormOpen = false;
    editingHabit = null;
    notifyListeners();
  }

  // --- Settings ---

  void updateSettings(AppSettings newSettings) {
    settings = newSettings;
    _storage.saveSettings(newSettings);
    if (user != null) {
      _firestore.saveUserSettings(user!.uid, newSettings).catchError((_) {});
    }
    notifyListeners();
  }

  // --- Factory reset ---

  Future<void> factoryReset() async {
    habits = getInitialHabits();
    logs = [];
    badges = List.from(kDefaultBadges);
    settings = AppSettings.defaults();
    selectedDate = getLocalDateString();
    activeTabIndex = 0;

    await _storage.clearAll();
    await _storage.saveHabits(habits);
    await _storage.saveBadges(badges);

    if (user != null) {
      await _firestore.clearUserData(user!.uid).catchError((_) {});
    }
    notifyListeners();
  }

  // --- Import ---

  Future<void> importData(List<Habit> importedHabits, List<HabitLog> importedLogs) async {
    habits = importedHabits;
    logs = importedLogs;
    await _storage.saveHabits(habits);
    await _storage.saveLogs(logs);
    if (user != null) {
      await _firestore.saveAllData(user!.uid, habits, logs, badges).catchError((_) {});
    }
    activeTabIndex = 0;
    notifyListeners();
  }

  // --- UI state ---

  void setActiveTab(int index) {
    activeTabIndex = index;
    notifyListeners();
  }

  void setSelectedDate(String date) {
    selectedDate = date;
    notifyListeners();
  }

  void setTimeOfDay(String tod) {
    selectedTimeOfDay = tod;
    notifyListeners();
  }

  void dismissBadgeToast() {
    unlockedBadgeToast = null;
    notifyListeners();
  }

  void dismissQuote() {
    settings = settings.copyWith(showQuote: false);
    _storage.saveSettings(settings);
    notifyListeners();
  }

  // --- Internal save helpers ---

  void _saveHabits(List<Habit> nextHabits, Habit? changed) {
    habits = nextHabits;
    _storage.saveHabits(habits);
    if (user != null && changed != null) {
      _firestore.saveHabit(user!.uid, changed).catchError((_) {});
    }
    notifyListeners();
  }

  void _saveLogs(List<HabitLog> nextLogs, HabitLog? changed) {
    logs = nextLogs;
    _storage.saveLogs(logs);

    final updatedBadges = checkBadges(habits, logs, badges);
    final newlyUnlocked = updatedBadges.asMap().entries.firstWhere(
      (e) => e.value.isUnlocked && !badges[e.key].isUnlocked,
      orElse: () => MapEntry(-1, badges.first),
    );

    if (newlyUnlocked.key >= 0) {
      unlockedBadgeToast = newlyUnlocked.value;
      Future.delayed(const Duration(seconds: 4), () {
        unlockedBadgeToast = null;
        notifyListeners();
      });
      if (user != null) {
        _firestore.saveBadge(user!.uid, newlyUnlocked.value).catchError((_) {});
      }
    }

    badges = updatedBadges;
    _storage.saveBadges(badges);

    if (user != null && changed != null) {
      _firestore.saveLog(user!.uid, changed).catchError((_) {});
    }

    notifyListeners();
  }
}
