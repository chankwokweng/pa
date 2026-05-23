import '../models/habit.dart';
import '../models/badge_model.dart';

List<Habit> getInitialHabits() {
  final now = DateTime.now().toIso8601String();
  return [
    Habit(
      id: 'habit-1',
      name: 'Hydrate Consistently',
      description: 'Drink 8 glasses of water throughout the day to stay active and fresh.',
      category: 'health',
      type: 'numeric',
      timeOfDay: 'anytime',
      targetValue: 8,
      targetUnit: 'glasses',
      createdAt: now,
      color: 'cyan',
      icon: 'GlassWater',
      isArchived: false,
    ),
    Habit(
      id: 'habit-2',
      name: 'Daily Mindfulness Meditation',
      description: 'Quiet the mind and focus on deliberate breathing.',
      category: 'mind',
      type: 'timer',
      timeOfDay: 'morning',
      targetValue: 600,
      targetUnit: 'secs',
      createdAt: now,
      color: 'violet',
      icon: 'Brain',
      isArchived: false,
    ),
    Habit(
      id: 'habit-3',
      name: 'Read Inspiring Literature',
      description: 'Read 20 pages of self-development or fiction books.',
      category: 'learning',
      type: 'numeric',
      timeOfDay: 'evening',
      targetValue: 20,
      targetUnit: 'pages',
      createdAt: now,
      color: 'amber',
      icon: 'BookOpen',
      isArchived: false,
    ),
    Habit(
      id: 'habit-4',
      name: 'Stretch Routine',
      description: 'Do a 15-minute mobility routine to preserve posture.',
      category: 'health',
      type: 'boolean',
      timeOfDay: 'morning',
      targetValue: 1,
      targetUnit: 'times',
      createdAt: now,
      color: 'emerald',
      icon: 'Dumbbell',
      isArchived: false,
    ),
  ];
}

const List<BadgeModel> kDefaultBadges = [
  BadgeModel(
    id: 'badge-first-step',
    title: 'First Step',
    description: 'Complete your first habit entry!',
    icon: 'CheckCircle2',
    category: 'total',
    requirementText: 'Log any habit as complete once',
  ),
  BadgeModel(
    id: 'badge-consistency-3',
    title: 'Habit Starter',
    description: 'Achieve a 3-day completion streak on any habit.',
    icon: 'Flame',
    category: 'streaks',
    requirementText: 'Active streak of 3 days on 1+ habits',
  ),
  BadgeModel(
    id: 'badge-consistency-7',
    title: '7-Day Warrior',
    description: 'Maintain a 7-day completion streak on any habit!',
    icon: 'Sparkles',
    category: 'streaks',
    requirementText: 'Active streak of 7 days on 1+ habits',
  ),
  BadgeModel(
    id: 'badge-centurion',
    title: 'Centurion Tracker',
    description: 'Log a total of 25 completed habits across the tracker.',
    icon: 'Coins',
    category: 'total',
    requirementText: 'Accumulate 25 total logs completed',
  ),
  BadgeModel(
    id: 'badge-mindful-master',
    title: 'Zen Master',
    description: 'Complete 5 counts of mind/meditation habits.',
    icon: 'Brain',
    category: 'category',
    requirementText: 'Complete Mind habits 5 times',
  ),
];

const List<Map<String, String>> kMotivationalQuotes = [
  {'text': 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.', 'author': 'Aristotle'},
  {'text': 'It is easier to prevent bad habits than to break them.', 'author': 'Benjamin Franklin'},
  {'text': 'Your habits will determine your future.', 'author': 'Jack Canfield'},
  {'text': 'Motivation is what gets you started. Habit is what keeps you going.', 'author': 'Jim Ryun'},
  {'text': 'Small daily improvements over time lead to stunning results.', 'author': 'Robin Sharma'},
  {'text': 'All big things come from small beginnings. The seed of every habit is a single, tiny decision.', 'author': 'James Clear'},
  {'text': 'You do not rise to the level of your goals. You fall to the level of your systems.', 'author': 'James Clear'},
];
