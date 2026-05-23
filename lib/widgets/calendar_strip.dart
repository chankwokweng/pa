import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CalendarStrip extends StatelessWidget {
  const CalendarStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final days = provider.calendarDays;
    const indigo = Color(0xFF6366F1);

    return Row(
      children: days.map((day) {
        final isSelected = day.isSelected;
        return Expanded(
          child: GestureDetector(
            onTap: () => provider.setSelectedDate(day.date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? indigo : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.dayName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.indigo.shade100 : Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.dayNum}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _dot(day.completionRatio, isSelected),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dot(double ratio, bool isSelected) {
    if (ratio <= 0) return const SizedBox(height: 6, width: 6);
    Color dotColor;
    if (isSelected) {
      dotColor = Colors.white;
    } else if (ratio >= 1) {
      dotColor = Colors.green.shade500;
    } else {
      dotColor = const Color(0xFF6366F1);
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
  }
}
