import 'package:flutter/material.dart';
import '../../../../i18n/i18n.dart';
import '../../../../models/entities/habit_model.dart';

/// 习惯表单对话框
class HabitFormDialog extends StatefulWidget {
  final APPi18n i18n;
  final void Function(String name, String? description, String? color) onSave;
  final HabitEntity? habit; // 如果传入则编辑模式

  const HabitFormDialog({
    super.key,
    required this.i18n,
    required this.onSave,
    this.habit,
  });

  @override
  State<HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedColor = '#4CAF50';

  // 预设颜色
  final List<String> _colorOptions = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#9C27B0', // Purple
    '#FF9800', // Orange
    '#E91E63', // Pink
    '#00BCD4', // Cyan
    '#F44336', // Red
    '#795548', // Brown
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description ?? '';
      _selectedColor = widget.habit!.color ?? '#4CAF50';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;

    return AlertDialog(
      title: Text(isEditing ? widget.i18n.editHabit : widget.i18n.addHabit),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 习惯名称
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: widget.i18n.habitName,
                hintText: widget.i18n.habitNamePlaceholder,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return widget.i18n.pleaseEnterTitle;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 描述（可选）
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: widget.i18n.habitDescription,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // 颜色选择
            Text(
              widget.i18n.habitColor,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.i18n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.i18n.save),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nameController.text.trim(),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        _selectedColor,
      );
      Navigator.of(context).pop();
    }
  }
}
