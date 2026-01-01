import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/i18n.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../providers/statistics_provider.dart';

/// 任务完成率卡片组件
class TaskCompletionCard extends StatelessWidget {
  final bool isDark;
  final APPi18n i18n;

  const TaskCompletionCard({
    super.key,
    required this.isDark,
    required this.i18n,
  });

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsProvider>();
    final completionRate = stats.taskCompletionRate;

    return GlassContainer(
      opacity: isDark ? 0.15 : 0.25,
      blur: 20,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                i18n.taskCompletionRate,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stats.taskCompletionRatePercent,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionRate,
              minHeight: 10,
              backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                i18n.tasksCompleted(stats.taskStats?.completedTasks ?? 0),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withAlpha(128),
                    ),
              ),
              Text(
                i18n.tasksTotal(stats.taskStats?.totalTasks ?? 0),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withAlpha(128),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
