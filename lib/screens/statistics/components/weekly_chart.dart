import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../i18n/i18n.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../providers/statistics_provider.dart';

/// 周趋势图表组件
class WeeklyChart extends StatefulWidget {
  final bool isDark;
  final APPi18n i18n;

  const WeeklyChart({
    super.key,
    required this.isDark,
    required this.i18n,
  });

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  /// 是否为桌面端
  bool get _isDesktop {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsProvider>();
    final dailyData = stats.weeklyTrend?.dailyData ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.i18n.weeklyFocusTrend,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: dailyData.isEmpty
              ? _buildEmptyChart(context)
              : _buildChart(context, dailyData),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, List<dynamic> dailyData) {
    // 计算最大高度参考值
    final maxMinutes = dailyData.isEmpty
        ? 120
        : dailyData.map((d) => d.focusMinutes).reduce((a, b) => a > b ? a : b);
    final heightReference = maxMinutes > 0 ? maxMinutes : 120;

    return GlassContainer(
      opacity: widget.isDark ? 0.1 : 0.2,
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

  Widget _buildEmptyChart(BuildContext context) {
    return GlassContainer(
      opacity: widget.isDark ? 0.1 : 0.2,
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
                widget.i18n.noFocusDataYet,
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
}
