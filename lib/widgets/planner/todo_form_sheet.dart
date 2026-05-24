import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/planner_provider.dart';

class TodoFormSheet extends StatefulWidget {
  const TodoFormSheet({super.key});

  @override
  State<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends State<TodoFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  String _priority = 'medium';
  String _status = 'pending';
  DateTime? _dueDate;
  String? _linkedHabitId;
  String? _category;
  List<String> _localCategories = [];

  static const _priorities = ['low', 'medium', 'high', 'urgent'];
  static const _statuses = ['pending', 'in_progress', 'completed', 'cancelled'];
  static const _priorityLabels = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
    'urgent': 'Urgent'
  };
  static const _statusLabels = {
    'pending': 'Pending',
    'in_progress': 'In Progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled'
  };

  @override
  void initState() {
    super.initState();
    final planner = context.read<PlannerProvider>();
    _localCategories = List<String>.from(planner.todoCategories);
    final editing = planner.editingTodo;
    if (editing != null) {
      _titleCtrl.text = editing.title;
      _descCtrl.text = editing.description;
      _detailsCtrl.text = editing.details;
      _priority = editing.priority;
      _status = editing.status;
      _linkedHabitId = editing.linkedHabitId;
      _category = editing.category;
      if (_category != null && !_localCategories.contains(_category)) {
        _localCategories.add(_category!);
      }
      if (editing.dueDate != null) {
        _dueDate = DateTime.parse(editing.dueDate!);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final planner = context.read<PlannerProvider>();
    planner.createOrUpdateTodo(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      details: _detailsCtrl.text.trim(),
      priority: _priority,
      dueDate: _dueDate != null
          ? '${_dueDate!.year.toString().padLeft(4, '0')}-'
              '${_dueDate!.month.toString().padLeft(2, '0')}-'
              '${_dueDate!.day.toString().padLeft(2, '0')}'
          : null,
      status: _status,
      linkedHabitId: _linkedHabitId,
      category: _category,
    );
    Navigator.of(context).pop();
  }

  Future<void> _addNewCategory() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Work, Personal'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_localCategories.contains(result)) {
          _localCategories = [..._localCategories, result];
        }
        _category = result;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final appProvider = context.watch<AppProvider>();
    final habits = appProvider.habits.where((h) => !h.isArchived).toList();
    final isEditing = planner.editingTodo != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
            _Handle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    isEditing ? 'Edit To-Do' : 'New To-Do',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      planner.clearEditingTodo();
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
                  _Field(
                    label: 'Title *',
                    child: TextField(
                      controller: _titleCtrl,
                      autofocus: true,
                      decoration: _inputDec('What needs to be done?'),
                    ),
                  ),
                  _Field(
                    label: 'Description',
                    child: TextField(
                      controller: _descCtrl,
                      decoration: _inputDec('Brief summary'),
                    ),
                  ),
                  _Field(
                    label: 'Details',
                    child: TextField(
                      controller: _detailsCtrl,
                      maxLines: 3,
                      decoration: _inputDec('Additional notes...'),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Priority',
                          child: DropdownButtonFormField<String>(
                            initialValue: _priority,
                            decoration: _inputDec(''),
                            items: _priorities
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(_priorityLabels[p]!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _priority = v!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Status',
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: _inputDec(''),
                            items: _statuses
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(_statusLabels[s]!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Field(
                    label: 'Due Date',
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _dueDate == null
                                  ? 'No due date'
                                  : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                              style: TextStyle(
                                color: _dueDate == null
                                    ? Colors.grey.shade500
                                    : null,
                              ),
                            ),
                            const Spacer(),
                            if (_dueDate != null)
                              GestureDetector(
                                onTap: () => setState(() => _dueDate = null),
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.grey.shade400),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _Field(
                    label: 'Category (optional)',
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey(_category),
                      initialValue: _category,
                      decoration: _inputDec('No category'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ..._localCategories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )),
                        const DropdownMenuItem(
                          value: '__new__',
                          child: Text(
                            '＋ New category',
                            style: TextStyle(color: Color(0xFF6366F1)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == '__new__') {
                          _addNewCategory();
                        } else {
                          setState(() => _category = v);
                        }
                      },
                    ),
                  ),
                  if (habits.isNotEmpty)
                    _Field(
                      label: 'Link to Habit (optional)',
                      child: DropdownButtonFormField<String?>(
                        initialValue: _linkedHabitId,
                        decoration: _inputDec('None'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('None')),
                          ...habits.map((h) => DropdownMenuItem(
                                value: h.id,
                                child: Text(h.name,
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setState(() => _linkedHabitId = v),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Add To-Do'),
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

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
