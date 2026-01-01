import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/i18n.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../providers/statistics_provider.dart';
import '../../../models/dtos/statistics_dto.dart';
import 'empty_state.dart';

/// 任务排行列表组件
class TaskRankingList extends StatelessWidget {
  final bool isDark;
  final APPi18n i18n;
  final bool isDesktop;

  const TaskRankingList({
    super.key,
    required this.isDark,
    required this.i18n,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              i18n.taskFocusRanking,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
            ),
            if (stats.taskFocusList.isNotEmpty)
              Text(
                i18n.topRanking(stats.taskFocusList.length),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isDesktop)
          _buildDesktopGrid(context, stats, screenWidth)
        else
          _buildMobileList(context, stats),
      ],
    );
  }

  Widget _buildDesktopGrid(
    BuildContext context,
    StatisticsProvider stats,
    double screenWidth,
  ) {
    final crossAxisCount = screenWidth >= 1200 ? 3 : (screenWidth >= 800 ? 2 : 1);

    if (stats.taskFocusList.isEmpty) {
      return EmptyState(
        icon: Icons.bar_chart_outlined,
        message: i18n.noFocusDataYet,
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats.taskFocusList.map((taskFocus) {
        return SizedBox(
          width: (screenWidth - 48 - 32) / crossAxisCount -
              ((crossAxisCount - 1) * 16) / crossAxisCount,
          child: _buildTaskCard(
            context,
            taskFocus,
            stats.taskFocusList.indexOf(taskFocus),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileList(BuildContext context, StatisticsProvider stats) {
    if (stats.taskFocusList.isEmpty) {
      return EmptyState(
        icon: Icons.bar_chart_outlined,
        message: i18n.noFocusDataYet,
      );
    }

    return Column(
      children: stats.taskFocusList.map((taskFocus) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildTaskCardMobile(
            context,
            taskFocus,
            stats.taskFocusList.indexOf(taskFocus),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskFocusStatsDTO taskFocus,
    int index,
  ) {
    return GlassContainer(
      opacity: isDark ? 0.08 : 0.15,
      blur: 10,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 排名徽章
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(index).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "#${index + 1}",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getRankColor(index),
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 任务信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskFocus.taskTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  i18n.focusSessions(taskFocus.sessions),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withAlpha(128),
                      ),
                ),
              ],
            ),
          ),
          // 专注时长
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${taskFocus.totalMinutes}",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              Text(
                i18n.minutes,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCardMobile(
    BuildContext context,
    TaskFocusStatsDTO taskFocus,
    int index,
  ) {
    return GlassContainer(
      opacity: isDark ? 0.08 : 0.15,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 排名徽章
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(index).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "#${index + 1}",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getRankColor(index),
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 任务信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskFocus.taskTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  i18n.focusSessions(taskFocus.sessions),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // 专注时长
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${taskFocus.totalMinutes}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              Text(
                i18n.minutes,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // 金色
    if (index == 1) return const Color(0xFFC0C0C0); // 银色
    if (index == 2) return const Color(0xFFCD7F32); // 铜色
    return Colors.grey;
  }
}
