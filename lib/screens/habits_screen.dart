import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/color_map.dart';
import '../utils/icon_map.dart';


class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeHabits = provider.habits.where((h) => !h.isArchived).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Habit Directory',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Your catalog of routine goals',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: provider.openCreateForm,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Create',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (activeHabits.isEmpty)
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.grey.shade200,
                      style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No active habits. Click Create to launch one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              )
            else
              ...activeHabits.map((h) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorFor(h.color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconFor(h.icon),
                          size: 22, color: colorFor(h.color)),
                    ),
                    title: Text(h.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${h.type} • ${h.type == 'timer' ? '${h.targetValue ~/ 60} mins' : '${h.targetValue} ${h.targetUnit}'} • ${h.timeOfDay}',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: Colors.grey.shade400),
                          onPressed: () => provider.openEditForm(h),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: Icon(Icons.archive_outlined,
                              size: 18, color: Colors.red.shade300),
                          onPressed: () => provider.requestArchive(h.id),
                          tooltip: 'Archive',
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),

        // Archive confirmation dialog
        if (provider.archiveHabitId != null)
          _ArchiveDialog(provider: provider),
      ],
    );
  }
}

class _ArchiveDialog extends StatelessWidget {
  final AppProvider provider;

  const _ArchiveDialog({required this.provider});

  @override
  Widget build(BuildContext context) {
    final habit =
        provider.habits.firstWhere((h) => h.id == provider.archiveHabitId);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Archive Habit',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(
          'Are you sure you want to archive "${habit.name}"? Historical stats will be preserved.'),
      actions: [
        TextButton(
            onPressed: provider.cancelArchive, child: const Text('Cancel')),
        FilledButton(
          onPressed: provider.confirmArchive,
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          child: const Text('Archive'),
        ),
      ],
    );
  }
}
