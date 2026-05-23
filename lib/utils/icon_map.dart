import 'package:flutter/material.dart';

const Map<String, IconData> kIconMap = {
  'Activity': Icons.monitor_heart,
  'BookOpen': Icons.menu_book,
  'Brain': Icons.psychology,
  'Flame': Icons.local_fire_department,
  'Sparkles': Icons.auto_awesome,
  'Coins': Icons.paid,
  'GlassWater': Icons.water_drop,
  'Heart': Icons.favorite,
  'Compass': Icons.explore,
  'Dumbbell': Icons.fitness_center,
  'Gamepad2': Icons.sports_esports,
  'CheckCircle2': Icons.check_circle_outline,
  'Moon': Icons.nightlight_round,
  'Coffee': Icons.coffee,
  'Music': Icons.music_note,
  'Smile': Icons.sentiment_satisfied,
  'LogOut': Icons.logout,
  'Settings': Icons.settings,
  'BarChart': Icons.bar_chart,
  'Star': Icons.star,
};

IconData iconFor(String name) => kIconMap[name] ?? Icons.circle;

const List<String> kIconOptions = [
  'Activity',
  'BookOpen',
  'Brain',
  'Flame',
  'Sparkles',
  'Coins',
  'GlassWater',
  'Heart',
  'Compass',
  'Dumbbell',
  'Gamepad2',
  'CheckCircle2',
  'Moon',
  'Coffee',
  'Music',
  'Smile',
];
