import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../i18n/i18n.dart';
import '../../widgets/glass/gradient_background.dart';
import '../../widgets/glass/glass_container.dart';
import '../../providers/statistics_provider.dart';
import '../../models/dtos/statistics_dto.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  /// 是否为桌面端（Windows/macOS/Linux 或 Web）
  bool get _isDesktop {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 获取响应式边距
  EdgeInsets get _responsivePadding {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return const EdgeInsets.symmetric(horizontal: 80, vertical: 24);
    } else if (screenWidth >= 800) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else {
      return const EdgeInsets.fromLTRB(24, kToolbarHeight + 24, 24, 24);
    }
  }

  /// 获取卡片宽度（桌面端可并排显示）
  double? _getCardWidth(double screenWidth) {
    if (screenWidth >= 800) {
      return (screenWidth - _responsivePadding.horizontal - 24) / 2;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: _isDesktop ? false : true,
      appBar: _isDesktop
          ? AppBar(
              title: Text(i18n.statistics),
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<StatisticsProvider>().loadAllData();
                  },
                ),
              ],
            )
          : AppBar(
              title: Text(i18n.statistics),
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<StatisticsProvider>().loadAllData();
                  },
                ),
              ],
            ),
      body: _isDesktop
          ? _buildDesktopLayout(context, i18n, isDark, screenWidth)
          : _buildMobileLayout(context, i18n, isDark),
    );
  }

  /// 桌面端布局
  Widget _buildDesktopLayout(
    BuildContext context,
    APPi18n i18n,
    bool isDark,
    double screenWidth,
  ) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[100],
      child: Consumer<StatisticsProvider>(
        builder: (context, stats, child) {
          if (stats.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final overviewCardWidth = _getCardWidth(screenWidth);

          return SingleChildScrollView(
            child: Padding(
              padding: _responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：概览卡片 + 任务完成率卡片（根据屏幕宽度选择布局）
                  screenWidth >= 800
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: overviewCardWidth,
                              child:
                                  _buildOverviewCard(context, stats, isDark, i18n),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: overviewCardWidth,
                              child: _buildTaskCompletionCard(
                                  context, stats, isDark, i18n),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOverviewCard(context, stats, isDark, i18n),
                            const SizedBox(height: 16),
                            _buildTaskCompletionCard(context, stats, isDark, i18n),
                          ],
                        ),
                  const SizedBox(height: 24),

                  // 第二行：周趋势图表（全宽）
                  Text(
                    i18n.weeklyFocusTrend,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: screenWidth - _responsivePadding.horizontal,
                    child: _buildWeeklyChart(context, stats, isDark, i18n),
                  ),

                  const SizedBox(height: 32),

                  // 第三行：任务专注排行
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

                  // 任务排行列表（网格布局）
                  _buildTaskFocusGrid(context, stats, isDark, i18n, screenWidth),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 任务专注排行网格（桌面端）
  Widget _buildTaskFocusGrid(
    BuildContext context,
    StatisticsProvider stats,
    bool isDark,
    APPi18n i18n,
    double screenWidth,
  ) {
    final crossAxisCount = screenWidth >= 1200 ? 3 : (screenWidth >= 800 ? 2 : 1);

    if (stats.taskFocusList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 64,
                color: Theme.of(context).hintColor.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                i18n.noFocusDataYet,
                style: TextStyle(
                  color: Theme.of(context).hintColor.withAlpha(128),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats.taskFocusList.map((taskFocus) {
        return SizedBox(
          width: (screenWidth - _responsivePadding.horizontal - 32) / crossAxisCount -
              ((crossAxisCount - 1) * 16) / crossAxisCount,
          child: _buildTaskFocusItemDesktop(
            context,
            taskFocus,
            stats.taskFocusList.indexOf(taskFocus),
            isDark,
            i18n,
          ),
        );
      }).toList(),
    );
  }

  /// 桌面端任务专注卡片
  Widget _buildTaskFocusItemDesktop(
    BuildContext context,
    TaskFocusStatsDTO taskFocus,
    int index,
    bool isDark,
    APPi18n i18n,
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

  /// 移动端布局
  Widget _buildMobileLayout(
    BuildContext context,
    APPi18n i18n,
    bool isDark,
  ) {
    return GradientBackground(
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
                      _buildOverviewCard(context, stats, isDark, i18n),
                      const SizedBox(height: 24),

                      // 任务完成率卡片
                      _buildTaskCompletionCard(context, stats, isDark, i18n),
                      const SizedBox(height: 24),

                      // 周统计图表
                      Text(
                        i18n.weeklyFocusTrend,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildWeeklyChart(context, stats, isDark, i18n),

                      const SizedBox(height: 32),
                      // 最近专注标题
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            i18n.taskFocusRanking,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (stats.taskFocusList.isNotEmpty)
                            Text(
                              i18n.topRanking(stats.taskFocusList.length),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 任务专注排行列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: stats.taskFocusList.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              i18n.noFocusDataYet,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final taskFocus = stats.taskFocusList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildTaskFocusItemMobile(
                                context,
                                taskFocus,
                                index,
                                isDark,
                                i18n,
                              ),
                            );
                          },
                          childCount: stats.taskFocusList.length,
                        ),
                      ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    StatisticsProvider stats,
    bool isDark,
    APPi18n i18n,
  ) {
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
                  "${stats.todayFocusMinutes}",
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
                  "${stats.thisWeekFocusMinutes}",
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
                  "${stats.totalFocusMinutes}",
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
                "${stats.todaySessions} ${i18n.sessionsToday}",
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

  Widget _buildTaskCompletionCard(
    BuildContext context,
    StatisticsProvider stats,
    bool isDark,
    APPi18n i18n,
  ) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              backgroundColor:
                  Theme.of(context).primaryColor.withAlpha(30),
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

  Widget _buildWeeklyChart(
    BuildContext context,
    StatisticsProvider stats,
    bool isDark,
    APPi18n i18n,
  ) {
    final dailyData = stats.weeklyTrend?.dailyData ?? [];

    if (dailyData.isEmpty) {
      return _buildEmptyChart(context, isDark, i18n);
    }

    // 计算最大高度参考值
    final maxMinutes = dailyData.isEmpty
        ? 120
        : dailyData.map((d) => d.focusMinutes).reduce((a, b) => a > b ? a : b);
    final heightReference = maxMinutes > 0 ? maxMinutes : 120;

    return GlassContainer(
      opacity: isDark ? 0.1 : 0.2,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: _isDesktop ? 220 : 180,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            // 倒序排列：周一到周日
            final reversedIndex = 6 - index;
            final data = dailyData.length > reversedIndex
                ? dailyData[reversedIndex]
                : null;

            final minutes = data?.focusMinutes ?? 0;
            final double heightFactor =
                (minutes / heightReference).clamp(0.05, 1.0);

            final dayDate =
                DateTime.now().subtract(Duration(days: reversedIndex));

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 数值标签
                  if (minutes > 0)
                    Text(
                      "$minutes",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: _isDesktop ? 11 : 9),
                    ),
                  const SizedBox(height: 4),
                  // 柱状图
                  Container(
                    width: _isDesktop ? 32 : 24,
                    height: (_isDesktop ? 150 : 120) * heightFactor,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          index == 6
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).primaryColor.withAlpha(80),
                          index == 6
                              ? Theme.of(context).primaryColor.withAlpha(180)
                              : Theme.of(context)
                                  .primaryColor
                                  .withAlpha(40),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_isDesktop ? 8 : 6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 星期标签
                  Text(
                    DateFormat('E').format(dayDate),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: _isDesktop ? 12 : 10),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, bool isDark, APPi18n i18n) {
    return GlassContainer(
      opacity: isDark ? 0.1 : 0.2,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: _isDesktop ? 220 : 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: _isDesktop ? 64 : 48,
                color: Theme.of(context).hintColor.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                i18n.noFocusDataYet,
                style: TextStyle(
                  color: Theme.of(context).hintColor.withAlpha(128),
                  fontSize: _isDesktop ? 16 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskFocusItemMobile(
    BuildContext context,
    TaskFocusStatsDTO taskFocus,
    int index,
    bool isDark,
    APPi18n i18n,
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
