import 'package:flutter/material.dart';

const Map<String, Color> kColorMap = {
  'emerald': Color(0xFF10B981),
  'violet': Color(0xFF8B5CF6),
  'amber': Color(0xFFF59E0B),
  'pink': Color(0xFFEC4899),
  'cyan': Color(0xFF06B6D4),
  'rose': Color(0xFFF43F5E),
  'indigo': Color(0xFF6366F1),
};

Color colorFor(String name) => kColorMap[name] ?? const Color(0xFF6366F1);

const List<Map<String, String>> kColorOptions = [
  {'id': 'emerald', 'name': 'Emerald Green'},
  {'id': 'violet', 'name': 'Violet Purple'},
  {'id': 'amber', 'name': 'Amber Gold'},
  {'id': 'pink', 'name': 'Hot Pink'},
  {'id': 'cyan', 'name': 'Electric Cyan'},
  {'id': 'rose', 'name': 'Rose Red'},
  {'id': 'indigo', 'name': 'Indigo Blue'},
];

class CategorySpec {
  final String id;
  final String name;
  final String icon;
  final Color color;

  const CategorySpec({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

const Map<String, CategorySpec> kCategorySpecs = {
  'health': CategorySpec(
    id: 'health',
    name: 'Body & Health',
    icon: 'Flame',
    color: Color(0xFF10B981),
  ),
  'mind': CategorySpec(
    id: 'mind',
    name: 'Mind & Focus',
    icon: 'Brain',
    color: Color(0xFF8B5CF6),
  ),
  'learning': CategorySpec(
    id: 'learning',
    name: 'Growth & Work',
    icon: 'BookOpen',
    color: Color(0xFFF59E0B),
  ),
  'creativity': CategorySpec(
    id: 'creativity',
    name: 'Creativity',
    icon: 'Sparkles',
    color: Color(0xFFEC4899),
  ),
  'finance': CategorySpec(
    id: 'finance',
    name: 'Financials',
    icon: 'Coins',
    color: Color(0xFF06B6D4),
  ),
};
