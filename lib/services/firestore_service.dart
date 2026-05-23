import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/badge_model.dart';
import '../models/app_settings.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _habitsCol(String uid) =>
      _db.collection('users').doc(uid).collection('habits');

  CollectionReference<Map<String, dynamic>> _logsCol(String uid) =>
      _db.collection('users').doc(uid).collection('logs');

  CollectionReference<Map<String, dynamic>> _badgesCol(String uid) =>
      _db.collection('users').doc(uid).collection('badges');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> saveHabit(String uid, Habit habit) =>
      _habitsCol(uid).doc(habit.id).set(_clean(habit.toJson()));

  Future<void> saveLog(String uid, HabitLog log) =>
      _logsCol(uid).doc(log.id).set(_clean(log.toJson()));

  Future<void> saveBadge(String uid, BadgeModel badge) =>
      _badgesCol(uid).doc(badge.id).set(_clean(badge.toJson()));

  Future<void> saveUserSettings(String uid, AppSettings settings) =>
      _userDoc(uid).set({'settings': _clean(settings.toJson())}, SetOptions(merge: true));

  Future<({List<Habit> habits, List<HabitLog> logs, List<BadgeModel> badges, AppSettings? settings})>
      loadUserData(String uid) async {
    final results = await Future.wait([
      _habitsCol(uid).get(),
      _logsCol(uid).get(),
      _badgesCol(uid).get(),
      _userDoc(uid).get(),
    ]);

    final habitsSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final logsSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final badgesSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final userSnap = results[3] as DocumentSnapshot<Map<String, dynamic>>;

    final habits = habitsSnap.docs.map((d) => Habit.fromJson(d.data())).toList();
    final logs = logsSnap.docs.map((d) => HabitLog.fromJson(d.data())).toList();
    final badges = badgesSnap.docs.map((d) => BadgeModel.fromJson(d.data())).toList();

    AppSettings? settings;
    final data = userSnap.data();
    if (data != null && data['settings'] != null) {
      settings = AppSettings.fromJson(data['settings'] as Map<String, dynamic>);
    }

    return (habits: habits, logs: logs, badges: badges, settings: settings);
  }

  Future<void> saveAllData(String uid, List<Habit> habits, List<HabitLog> logs,
      List<BadgeModel> badges) async {
    const batchLimit = 499;
    var batch = _db.batch();
    int count = 0;

    void flush() async {
      await batch.commit();
      batch = _db.batch();
      count = 0;
    }

    for (final h in habits) {
      batch.set(_habitsCol(uid).doc(h.id), _clean(h.toJson()));
      if (++count >= batchLimit) flush();
    }
    for (final l in logs) {
      batch.set(_logsCol(uid).doc(l.id), _clean(l.toJson()));
      if (++count >= batchLimit) flush();
    }
    for (final b in badges) {
      batch.set(_badgesCol(uid).doc(b.id), _clean(b.toJson()));
      if (++count >= batchLimit) flush();
    }
    if (count > 0) await batch.commit();
  }

  Future<void> clearUserData(String uid) async {
    final cols = [_habitsCol(uid), _logsCol(uid), _badgesCol(uid)];
    for (final col in cols) {
      final snap = await col.get();
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await _userDoc(uid).delete();
  }

  // Strip null values — Firestore rejects undefined/null fields
  Map<String, dynamic> _clean(Map<String, dynamic> data) =>
      Map.fromEntries(data.entries.where((e) => e.value != null));
}
