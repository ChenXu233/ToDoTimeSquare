import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/i18n.dart';
import '../../../models/entities/habit_model.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../providers/statistics_provider.dart';
import 'habit_form_dialog.dart';

/// 习惯追踪区块组件
class HabitTrackingSection extends StatefulWidget {
  final bool isDark;
  final APPi18n i18n;

  const HabitTrackingSection({
    super.key,
    required this.isDark,
    required this.i18n,
  });

  @override
  State<HabitTrackingSection> createState() => _HabitTrackingSectionState();
}

class _HabitTrackingSectionState extends State<HabitTrackingSection> {
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.i18n.habitTracking,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
            ),
            Text(
              '${stats.checkedInTodayCount}/${stats.totalActiveHabits} ${widget.i18n.checkedIn}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 习惯列表或空状态
        if (stats.habits.isEmpty)
          _buildEmptyState()
        else
          _buildHabitGrid(context, stats),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      opacity: widget.isDark ? 0.08 : 0.15,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
          Icon(
            Icons.loop_outlined,
            size: 48,
            color: Theme.of(context).hintColor.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            widget.i18n.noHabitsYet,
            style: TextStyle(
              color: Theme.of(context).hintColor.withAlpha(128),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _showAddHabitDialog(context),
            icon: const Icon(Icons.add),
            label: Text(widget.i18n.addHabit),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHabitGrid(BuildContext context, StatisticsProvider stats) {
    return Column(
      children: [
        // 习惯卡片列表
        ...stats.habits.map((habit) => _buildHabitCard(context, habit, stats)),
        const SizedBox(height: 16),
        // 添加习惯按钮
        TextButton.icon(
          onPressed: () => _showAddHabitDialog(context),
          icon: const Icon(Icons.add_circle_outline),
          label: Text(widget.i18n.addHabit),
        ),
      ],
    );
  }

  Widget _buildHabitCard(BuildContext context, HabitEntity habit, StatisticsProvider stats) {
    final isCheckedIn = stats.isHabitCheckedInToday(habit.id);
    final streak = stats.getHabitStreak(habit.id);
    final color = _parseColor(habit.color);

    return GlassContainer(
      opacity: widget.isDark ? 0.08 : 0.15,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 颜色指示器
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          // 习惯信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (habit.description != null && habit.description!.isNotEmpty)
                  Text(
                    habit.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withAlpha(128),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '$streak ${widget.i18n.streakDays}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 打卡按钮
          _buildCheckInButton(context, habit, isCheckedIn),
        ],
      ),
    );
  }

  Widget _buildCheckInButton(
    BuildContext context,
    HabitEntity habit,
    bool isCheckedIn,
  ) {
    final stats = context.read<StatisticsProvider>();

    return InkWell(
      onTap: () async {
        if (isCheckedIn) {
          await stats.uncheckHabit(habit.id);
        } else {
          await stats.checkInHabit(habit.id);
          if (mounted) {
            _showCheckInSuccess(widget.i18n);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCheckedIn
              ? Colors.green.withAlpha(30)
              : Theme.of(context).primaryColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCheckedIn ? Colors.green : Theme.of(context).primaryColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCheckedIn ? Icons.check_circle : Icons.add_circle_outline,
              size: 20,
              color: isCheckedIn ? Colors.green : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              isCheckedIn ? widget.i18n.checkedIn : widget.i18n.checkIn,
              style: TextStyle(
                color: isCheckedIn ? Colors.green : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => HabitFormDialog(
        i18n: widget.i18n,
        onSave: (name, description, color) {
          context.read<StatisticsProvider>().createHabit(
                name: name,
                description: description,
                color: color,
              );
        },
      ),
    );
  }

  void _showCheckInSuccess(APPi18n i18n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(i18n.checkInSuccess),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF4CAF50);
    }
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }
}
