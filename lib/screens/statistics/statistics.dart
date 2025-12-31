import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../i18n/i18n.dart';
import '../../widgets/glass/gradient_background.dart';
import '../../providers/statistics_provider.dart';
import 'components/overview_card.dart';
import 'components/task_completion_card.dart';
import 'components/weekly_chart.dart';
import 'components/task_ranking_list.dart';
import 'components/habit_tracking_section.dart';

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
                  // 第一行：概览卡片 + 任务完成率卡片
                  screenWidth >= 800
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              SizedBox(
                                width: overviewCardWidth,
                                child: OverviewCard(isDark: isDark, i18n: i18n),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: overviewCardWidth,
                                child: TaskCompletionCard(isDark: isDark, i18n: i18n),
                              ),
                            ])
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OverviewCard(isDark: isDark, i18n: i18n),
                            const SizedBox(height: 16),
                            TaskCompletionCard(isDark: isDark, i18n: i18n),
                          ],
                        ),
                  const SizedBox(height: 24),

                  // 第二行：周趋势图表（全宽）
                  WeeklyChart(isDark: isDark, i18n: i18n),

                  const SizedBox(height: 32),

                  // 第三行：任务专注排行
                  TaskRankingList(
                    isDark: isDark,
                    i18n: i18n,
                    isDesktop: true,
                  ),

                  const SizedBox(height: 32),

                  // 第四行：习惯追踪区块
                  HabitTrackingSection(isDark: isDark, i18n: i18n),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
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
                      // 顶部概览卡片
                      OverviewCard(isDark: isDark, i18n: i18n),
                      const SizedBox(height: 16),

                      // 任务完成率卡片
                      TaskCompletionCard(isDark: isDark, i18n: i18n),
                      const SizedBox(height: 24),

                      // 周趋势图表
                      WeeklyChart(isDark: isDark, i18n: i18n),

                      const SizedBox(height: 24),

                      // 任务专注排行标题
                      Text(
                        i18n.taskFocusRanking,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 任务专注排行列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: TaskRankingList(
                  isDark: isDark,
                  i18n: i18n,
                  isDesktop: false,
                ),
              ),

              // 习惯追踪区块
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: HabitTrackingSection(isDark: isDark, i18n: i18n),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
