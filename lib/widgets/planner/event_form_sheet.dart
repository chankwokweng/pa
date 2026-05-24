import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/planner_provider.dart';

const _colorOptions = ['blue', 'green', 'red', 'orange', 'purple', 'teal'];
const _colorValues = {
  'blue': Color(0xFF3B82F6),
  'green': Color(0xFF10B981),
  'red': Color(0xFFEF4444),
  'orange': Color(0xFFF97316),
  'purple': Color(0xFF8B5CF6),
  'teal': Color(0xFF14B8A6),
};

class EventFormSheet extends StatefulWidget {
  const EventFormSheet({super.key});

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _isAllDay = false;
  bool _syncToGoogle = false;
  String _color = 'blue';
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  @override
  void initState() {
    super.initState();
    final planner = context.read<PlannerProvider>();
    final editing = planner.editingEvent;
    if (editing != null) {
      _titleCtrl.text = editing.title;
      _descCtrl.text = editing.description;
      _locationCtrl.text = editing.location;
      _isAllDay = editing.isAllDay;
      _color = editing.color;
      _syncToGoogle = editing.isSynced;

      final start = editing.startDateLocal;
      _startDate = start;
      _startTime = TimeOfDay(hour: start.hour, minute: start.minute);

      final end = editing.endDateLocal;
      if (end != null) {
        _endDate = end;
        _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
      } else {
        _endDate = start.add(const Duration(hours: 1));
        _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);
      }
    } else {
      final now = DateTime.now();
      _endDate = now;
      _endTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  DateTime get _startDateTime => DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _isAllDay ? 0 : _startTime.hour,
        _isAllDay ? 0 : _startTime.minute,
      );

  DateTime get _endDateTime => DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _isAllDay ? 0 : _endTime.hour,
        _isAllDay ? 0 : _endTime.minute,
      );

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final planner = context.read<PlannerProvider>();
    final calendarConnected = planner.isCalendarConnected;

    await planner.createOrUpdateEvent(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      startDateTime: _startDateTime.toIso8601String(),
      endDateTime: _endDateTime.toIso8601String(),
      isAllDay: _isAllDay,
      color: _color,
      syncToGoogle: _syncToGoogle && calendarConnected,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final isEditing = planner.editingEvent != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _handle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    isEditing ? 'Edit Event' : 'New Event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      planner.clearEditingEvent();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),
                  _field(
                    'Title *',
                    TextField(
                      controller: _titleCtrl,
                      autofocus: true,
                      decoration: _dec('Event title'),
                    ),
                  ),
                  _field(
                    'Description',
                    TextField(
                      controller: _descCtrl,
                      decoration: _dec('Add a description'),
                    ),
                  ),
                  _field(
                    'Location',
                    TextField(
                      controller: _locationCtrl,
                      decoration: _dec('Add a location'),
                    ),
                  ),
                  // All day toggle
                  Row(
                    children: [
                      const Text('All Day',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Switch(
                        value: _isAllDay,
                        onChanged: (v) => setState(() => _isAllDay = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Start
                  _field(
                    'Start',
                    Row(
                      children: [
                        Expanded(
                          child: _dateTile(
                              DateFormat('EEE, MMM d, yyyy').format(_startDate),
                              () => _pickDate(true)),
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(width: 8),
                          _timeTile(_startTime.format(context),
                              () => _pickTime(true)),
                        ],
                      ],
                    ),
                  ),
                  // End
                  _field(
                    'End',
                    Row(
                      children: [
                        Expanded(
                          child: _dateTile(
                              DateFormat('EEE, MMM d, yyyy').format(_endDate),
                              () => _pickDate(false)),
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(width: 8),
                          _timeTile(_endTime.format(context),
                              () => _pickTime(false)),
                        ],
                      ],
                    ),
                  ),
                  // Color picker
                  _field(
                    'Color',
                    Row(
                      children: _colorOptions.map((c) {
                        final color = _colorValues[c]!;
                        final selected = _color == c;
                        return GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: Colors.white, width: 2)
                                  : null,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 6)
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Google Calendar sync
                  if (planner.isCalendarConnected)
                    Row(
                      children: [
                        const Icon(Icons.sync, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                            child: Text('Sync to Google Calendar',
                                style: TextStyle(fontWeight: FontWeight.w500))),
                        Switch(
                          value: _syncToGoogle,
                          onChanged: (v) => setState(() => _syncToGoogle = v),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Add Event'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      );

  Widget _dateTile(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            ],
          ),
        ),
      );

  Widget _timeTile(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 14),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _handle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      );
}
