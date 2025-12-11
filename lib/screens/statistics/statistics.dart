import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../i18n/i18n.dart';
import '../../widgets/glass/gradient_background.dart';
import '../../widgets/glass/glass_container.dart';
import '../../providers/statistics_provider.dart';
import '../../models/focus_record.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(i18n.statistics),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: GradientBackground(
        child: Consumer<StatisticsProvider>(
          builder: (context, stats, child) {
            if (stats.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      kToolbarHeight + 24,
                      24,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顶部总览卡片
                        _buildOverviewCard(context, stats, isDark),
                        const SizedBox(height: 24),

                        // 周统计图表
                        Text(
                          "本周概览",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildWeeklyChart(context, stats, isDark),
                        
                        const SizedBox(height: 32),
                        Text(
                          "最近专注",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // 历史记录列表
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: stats.records.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                "暂无专注记录",
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final record = stats.recentRecords[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildRecordItem(context, record, isDark),
                            );
                          }, childCount: stats.recentRecords.length),
                        ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    StatisticsProvider stats,
    bool isDark,
  ) {
    return GlassContainer(
      opacity: isDark ? 0.15 : 0.25,
      blur: 20,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                "今日专注",
                "${stats.todayFocusMinutes}",
                "分钟",
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
              _buildStatItem(
                context,
                "累计专注",
                "${stats.totalFocusMinutes}",
                "分钟",
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(unit, style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
    BuildContext context,
    StatisticsProvider stats,
    bool isDark,
  ) {
    // 获取过去7天的数据（简化版，实际应从provider获取每日数据）
    // 这里我们简单模拟一下，或者如果provider没有提供每日数据，我们暂时显示一个占位或者简单的可视化
    // 为了"高级感"，我们用一组柱状图表示
    
    return GlassContainer(
      opacity: isDark ? 0.1 : 0.2,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            // 模拟数据高度，实际应根据 stats.dailyFocus[index] 计算
            // 由于 StatisticsProvider 还没提供每日数据，我们暂时用随机高度展示UI效果
            // 或者我们可以快速计算一下
            final day = DateTime.now().subtract(Duration(days: 6 - index));
            final dayMinutes = stats.records
                .where(
                  (r) =>
                      r.startTime.year == day.year &&
                      r.startTime.month == day.month &&
                      r.startTime.day == day.day,
                )
                .fold(0, (sum, r) => sum + (r.durationSeconds ~/ 60));

            // Normalize height (max 120 mins for full height)
            final double heightFactor = (dayMinutes / 120).clamp(0.1, 1.0);

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 12,
                  height: 100 * heightFactor,
                  decoration: BoxDecoration(
                    color: index == 6
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('E').format(day), // Mon, Tue...
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecordItem(
    BuildContext context,
    FocusRecord record,
    bool isDark,
  ) {
    return GlassContainer(
      opacity: isDark ? 0.08 : 0.15,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.taskTitle ?? "无标题专注",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(record.startTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${record.durationSeconds ~/ 60}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                "分钟",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
