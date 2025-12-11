import 'package:flutter/material.dart';
import '../../../models/todo.dart';
import '../../../i18n/i18n.dart';
import '../../../widgets/glass/glass_container.dart';
import 'task_meta_row.dart';

class TaskTray extends StatefulWidget {
  final Todo task;
  final bool isExpanded;
  final Color fgColor;
  final Color bgColor;
  final bool isDark;
  final ThemeData theme;
  final APPi18n i18n;
  final VoidCallback onExpand;
  final bool showMeta;

  const TaskTray({
    super.key,
    required this.task,
    required this.isExpanded,
    required this.fgColor,
    required this.bgColor,
    required this.isDark,
    required this.theme,
    required this.i18n,
    required this.onExpand,
    this.showMeta = true,
  });

  @override
  State<TaskTray> createState() => _TaskTrayState();
}

class _TaskTrayState extends State<TaskTray>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double collapsedMargin = screenWidth < 380 ? 72.0 : 84.0;
    final double expandedMargin = 24.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(
            widget.isExpanded ? expandedMargin : collapsedMargin,
            0,
            widget.isExpanded ? expandedMargin : collapsedMargin,
            16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: GlassContainer(
                color: widget.isDark ? Colors.white : Colors.black,
                opacity: 0.08,
                borderRadius: BorderRadius.circular(24),
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: widget.onExpand,
                    child: Padding(
                      padding: EdgeInsets.all(widget.isExpanded ? 24.0 : 20.0),
                      child: widget.isExpanded
                          ? _ExpandedContent(
                              task: widget.task,
                              fgColor: widget.fgColor,
                              theme: widget.theme,
                              i18n: widget.i18n,
                            )
                          : _CollapsedContent(
                              task: widget.task,
                              fgColor: widget.fgColor,
                              theme: widget.theme,
                              onTap: widget.onExpand,
                              showMeta: widget.showMeta,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedContent extends StatelessWidget {
  final Todo task;
  final Color fgColor;
  final ThemeData theme;
  final VoidCallback onTap;
  final bool showMeta;

  const _CollapsedContent({
    required this.task,
    required this.fgColor,
    required this.theme,
    required this.onTap,
    required this.showMeta,
  });

  @override
  Widget build(BuildContext context) {
    if (!showMeta) {
      return Container(
        alignment: Alignment.center,
        child: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        TaskMetaRow(task: task, fgColor: fgColor),
      ],
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final Todo task;
  final Color fgColor;
  final ThemeData theme;
  final APPi18n i18n;

  const _ExpandedContent({
    required this.task,
    required this.fgColor,
    required this.theme,
    required this.i18n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, color: fgColor, size: 20),
            const SizedBox(width: 8),
            Text(
              i18n.currentTask,
              style: theme.textTheme.titleMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          task.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (task.description != null && task.description!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fgColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.description!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fgColor.withOpacity(0.8),
              ),
            ),
          ),
        TaskMetaRow(task: task, fgColor: fgColor),
      ],
    );
  }
}
