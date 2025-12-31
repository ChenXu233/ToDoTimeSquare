import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/i18n.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../providers/statistics_provider.dart';

/// 概览卡片组件
class OverviewCard extends StatelessWidget {
  final bool isDark;
  final APPi18n i18n;

  const OverviewCard({
    super.key,
    required this.isDark,
    required this.i18n,
  });

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsProvider>();

    return GlassContainer(
      opacity: isDark ? 0.15 : 0.25,
      blur: 20,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: _buildStatItem(
                  context,
                  i18n.todayFocus,
                  '${stats.todayFocusMinutes}',
                  i18n.minutes,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withAlpha(70),
              ),
              Flexible(
                child: _buildStatItem(
                  context,
                  i18n.thisWeekFocus,
                  '${stats.thisWeekFocusMinutes}',
                  i18n.minutes,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withAlpha(70),
              ),
              Flexible(
                child: _buildStatItem(
                  context,
                  i18n.totalFocus,
                  '${stats.totalFocusMinutes}',
                  i18n.minutes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: Theme.of(context).primaryColor.withAlpha(180),
              ),
              const SizedBox(width: 8),
              Text(
                '${stats.todaySessions} ${i18n.sessionsToday}',
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

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(128),
              ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
