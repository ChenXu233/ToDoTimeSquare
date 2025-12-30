import 'package:flutter/material.dart';
import '../../../models/models.dart';

class TaskMetaRow extends StatelessWidget {
  final TaskModel task;
  final Color fgColor;

  const TaskMetaRow({super.key, required this.task, required this.fgColor});

  String? get durationLabel {
    final minutes = task.estimatedDuration;
    if (minutes == null) return null;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0 && remainingMinutes > 0)
      return '${hours}h ${remainingMinutes}m';
    if (hours > 0) return '${hours}h';
    return '${remainingMinutes}m';
  }

  String? get startLabel {
    final start = task.plannedStartTime;
    if (start == null) return null;
    final hour = start.hour.toString().padLeft(2, '0');
    final minute = start.minute.toString().padLeft(2, '0');
    return '${start.month}/${start.day} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (durationLabel != null) {
      chips.add(
        MetaChip(
          icon: Icons.timer_outlined,
          label: durationLabel!,
          fgColor: fgColor,
        ),
      );
    }
    if (startLabel != null) {
      chips.add(
        MetaChip(icon: Icons.schedule, label: startLabel!, fgColor: fgColor),
      );
    }
    if (chips.isEmpty) {
      return Text('No Meta', style: TextStyle(color: fgColor.withAlpha(150)));
    }
    return Wrap(spacing: 12, runSpacing: 8, children: chips);
  }
}

class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fgColor;

  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: fgColor.withAlpha(((0.2) * 255).round())),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fgColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
