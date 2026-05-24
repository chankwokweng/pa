import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/color_map.dart';
import '../utils/icon_map.dart';

class HabitFormSheet extends StatefulWidget {
  const HabitFormSheet({super.key});

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _category = 'health';
  String _type = 'boolean';
  String _timeOfDay = 'anytime';
  String _color = 'indigo';
  String _icon = 'Activity';

  @override
  void initState() {
    super.initState();
    final editing = context.read<AppProvider>().editingHabit;
    if (editing != null) {
      _nameCtrl.text = editing.name;
      _descCtrl.text = editing.description;
      _targetCtrl.text = editing.targetValue.toString();
      _unitCtrl.text = editing.targetUnit;
      _category = editing.category;
      _type = editing.type;
      _timeOfDay = editing.timeOfDay;
      _color = editing.color;
      _icon = editing.icon;
    } else {
      _targetCtrl.text = '1';
      _unitCtrl.text = 'times';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppProvider>().createOrUpdateHabit(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          type: _type,
          timeOfDay: _timeOfDay,
          targetValue: int.tryParse(_targetCtrl.text) ?? 1,
          targetUnit: _unitCtrl.text.trim(),
          color: _color,
          icon: _icon,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = context.read<AppProvider>().editingHabit != null;
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Habit' : 'Create Habit',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _field('Name', _nameCtrl,
                        hint: 'e.g. Morning Run',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    _field('Description', _descCtrl,
                        hint: 'Optional details...', maxLines: 2),
                    const SizedBox(height: 14),

                    // Category
                    _label('Category'),
                    const SizedBox(height: 6),
                    _segmentRow(
                      options: kCategorySpecs.keys.toList(),
                      labels: kCategorySpecs.values.map((s) => s.name).toList(),
                      selected: _category,
                      onSelect: (v) => setState(() => _category = v),
                    ),
                    const SizedBox(height: 14),

                    // Type
                    _label('Type'),
                    const SizedBox(height: 6),
                    _segmentRow(
                      options: const ['boolean', 'numeric', 'timer'],
                      labels: const ['Boolean', 'Numeric', 'Timer'],
                      selected: _type,
                      onSelect: (v) {
                        setState(() {
                          _type = v;
                          if (v == 'boolean') {
                            _targetCtrl.text = '1';
                            _unitCtrl.text = 'times';
                          } else if (v == 'timer') {
                            _targetCtrl.text = '600';
                            _unitCtrl.text = 'secs';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Time of Day
                    _label('Time of Day'),
                    const SizedBox(height: 6),
                    _segmentRow(
                      options: const ['anytime', 'morning', 'afternoon', 'evening'],
                      labels: const ['Anytime', 'Morning', 'Afternoon', 'Evening'],
                      selected: _timeOfDay,
                      onSelect: (v) => setState(() => _timeOfDay = v),
                    ),
                    const SizedBox(height: 14),

                    if (_type != 'boolean') ...[
                      Row(children: [
                        Expanded(
                          child: _field(
                            _type == 'timer' ? 'Target (secs)' : 'Target',
                            _targetCtrl,
                            hint: _type == 'timer' ? '600' : '8',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                        if (_type == 'numeric') ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field('Unit', _unitCtrl, hint: 'e.g. glasses'),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 14),
                    ],

                    // Color
                    _label('Color'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kColorOptions.map((c) {
                        final id = c['id']!;
                        final col = colorFor(id);
                        final selected = _color == id;
                        return GestureDetector(
                          onTap: () => setState(() => _color = id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 8)]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Icon
                    _label('Icon'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kIconOptions.map((name) {
                        final selected = _icon == name;
                        return GestureDetector(
                          onTap: () => setState(() => _icon = name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorFor(_color)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              iconFor(name),
                              size: 20,
                              color: selected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Habit',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.grey),
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _segmentRow({
    required List<String> options,
    required List<String> labels,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = selected == options[i];
          return GestureDetector(
            onTap: () => onSelect(options[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
