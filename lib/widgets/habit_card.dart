import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../providers/app_provider.dart';
import '../utils/color_map.dart';
import '../utils/date_utils.dart';
import '../utils/icon_map.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final HabitLog? log;
  final int currentStreak;

  const HabitCard({
    super.key,
    required this.habit,
    required this.log,
    required this.currentStreak,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  Timer? _timer;
  bool _timerRunning = false;
  late int _timeLeft;

  @override
  void initState() {
    super.initState();
    _timeLeft = _computeTimeLeft();
  }

  @override
  void didUpdateWidget(HabitCard old) {
    super.didUpdateWidget(old);
    if (old.log?.value != widget.log?.value) {
      setState(() => _timeLeft = _computeTimeLeft());
    }
  }

  int _computeTimeLeft() {
    final current = widget.log?.value ?? 0;
    return (widget.habit.targetValue - current).clamp(0, widget.habit.targetValue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer(AppProvider provider) {
    if (_timerRunning) {
      _timer?.cancel();
      setState(() => _timerRunning = false);
    } else {
      setState(() => _timerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _timeLeft--;
          if (_timeLeft <= 0) {
            _timeLeft = 0;
            _timerRunning = false;
            t.cancel();
            provider.updateProgress(widget.habit.id, widget.habit.targetValue);
          } else if (_timeLeft % 5 == 0) {
            provider.updateProgress(
                widget.habit.id, widget.habit.targetValue - _timeLeft);
          }
        });
      });
    }
  }

  void _resetTimer(AppProvider provider) {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      _timeLeft = widget.habit.targetValue;
    });
    provider.updateProgress(widget.habit.id, 0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final habit = widget.habit;
    final log = widget.log;
    final isCompleted = log?.isCompleted ?? false;
    final currentValue = log?.value ?? 0;

    final habitColor = colorFor(habit.color);
    final spec = kCategorySpecs[habit.category] ?? kCategorySpecs['health']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? habitColor.withValues(alpha: 0.4)
              : isDark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFE5E7EB),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isCompleted)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: habitColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? habitColor
                            : spec.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconFor(habit.icon),
                        size: 22,
                        color: isCompleted ? Colors.white : spec.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? Colors.grey.shade400
                                  : null,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: spec.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  spec.name,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: spec.color,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              if (habit.timeOfDay != 'anytime') ...[
                                const SizedBox(width: 6),
                                Icon(
                                  _timeIcon(habit.timeOfDay),
                                  size: 10,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  habit.timeOfDay,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade400),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Options button
                    _OptionsMenu(
                      habit: habit,
                      onEdit: () => provider.openEditForm(habit),
                      onArchive: () => provider.requestArchive(habit.id),
                    ),
                  ],
                ),

                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    habit.description,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // Footer: streak + controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Streak
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 18,
                          color: widget.currentStreak > 0
                              ? Colors.amber.shade500
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.currentStreak}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'STREAK',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Type controls
                    if (habit.type == 'boolean')
                      _BoolControl(
                          isCompleted: isCompleted,
                          habitColor: habitColor,
                          onToggle: () => provider.updateProgress(
                              habit.id, isCompleted ? 0 : 1)),
                    if (habit.type == 'numeric')
                      _NumericControl(
                        current: currentValue,
                        target: habit.targetValue,
                        unit: habit.targetUnit,
                        isCompleted: isCompleted,
                        onDecrement: () => provider.updateProgress(
                            habit.id, (currentValue - 1).clamp(0, 9999)),
                        onIncrement: () =>
                            provider.updateProgress(habit.id, currentValue + 1),
                      ),
                    if (habit.type == 'timer')
                      _TimerControl(
                        timeLeft: _timeLeft,
                        target: habit.targetValue,
                        isCompleted: isCompleted,
                        isRunning: _timerRunning,
                        onToggle: () => _toggleTimer(provider),
                        onReset: () => _resetTimer(provider),
                        onSkip: () {
                          _timer?.cancel();
                          setState(() {
                            _timerRunning = false;
                            _timeLeft = 0;
                          });
                          provider.updateProgress(
                              habit.id, habit.targetValue);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _timeIcon(String t) {
    if (t == 'morning') return Icons.coffee;
    if (t == 'afternoon') return Icons.explore;
    return Icons.nightlight_round;
  }
}

class _BoolControl extends StatelessWidget {
  final bool isCompleted;
  final Color habitColor;
  final VoidCallback onToggle;

  const _BoolControl(
      {required this.isCompleted,
      required this.habitColor,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: isCompleted ? Colors.white : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              isCompleted ? 'Done' : 'Check Off',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCompleted ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumericControl extends StatelessWidget {
  final int current;
  final int target;
  final String unit;
  final bool isCompleted;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _NumericControl({
    required this.current,
    required this.target,
    required this.unit,
    required this.isCompleted,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CtrlBtn(
          onTap: current > 0 ? onDecrement : null,
          child: const Text('-',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            Text(
              '$current',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color:
                    isCompleted ? Colors.green.shade500 : Colors.grey.shade800,
              ),
            ),
            Text(
              '/ $target $unit',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _CtrlBtn(
          onTap: onIncrement,
          child: const Text('+',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _TimerControl extends StatelessWidget {
  final int timeLeft;
  final int target;
  final bool isCompleted;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final VoidCallback onSkip;

  const _TimerControl({
    required this.timeLeft,
    required this.target,
    required this.isCompleted,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Done!',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade500),
          ),
          const SizedBox(width: 8),
          _CtrlBtn(
            onTap: onReset,
            child: Text('Reset',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatDuration(timeLeft),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800),
            ),
            Text(
              '${formatDuration(target)} target',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isRunning
                  ? Colors.amber.shade500
                  : const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 4),
        _CtrlBtn(
          onTap: onSkip,
          child: const Icon(Icons.check_circle_outline,
              size: 14, color: Colors.grey),
        ),
      ],
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CtrlBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Opacity(opacity: onTap == null ? 0.4 : 1.0, child: child),
      ),
    );
  }
}

class _OptionsMenu extends StatefulWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _OptionsMenu(
      {required this.habit, required this.onEdit, required this.onArchive});

  @override
  State<_OptionsMenu> createState() => _OptionsMenuState();
}

class _OptionsMenuState extends State<_OptionsMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) {
        if (v == 'edit') widget.onEdit();
        if (v == 'archive') widget.onArchive();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 16),
            SizedBox(width: 8),
            Text('Edit Details'),
          ]),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(children: [
            Icon(Icons.archive_outlined, size: 16, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Text('Archive', style: TextStyle(color: Colors.red.shade500)),
          ]),
        ),
      ],
    );
  }
}
