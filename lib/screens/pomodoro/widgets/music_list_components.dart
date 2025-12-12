import 'package:flutter/material.dart';

class TrackTile extends StatelessWidget {
  final dynamic track;
  final bool isPlaying;
  final bool isDark;
  final IconData leadingIcon;
  final Color? leadingColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const TrackTile({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.isDark,
    required this.leadingIcon,
    this.leadingColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: isPlaying ? BorderRadius.circular(24) : BorderRadius.circular(8),
        color: isPlaying ? (isDark ? Colors.grey[800]!.withAlpha(100) : Colors.grey[200]!.withAlpha(100)) : Colors.white.withAlpha(10),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: isDark ? Colors.white.withAlpha(70) : primary.withAlpha(70),
                  spreadRadius: 4,
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: ListTile(
        title: Text(
          track.title ?? '',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        subtitle: Text(
          track.artist ?? '',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        leading: Icon(
          leadingIcon,
          color: isPlaying ? primary : (leadingColor ?? (isDark ? Colors.white60 : Colors.black54)),
        ),
        trailing: trailing,
        onTap: onTap,
        selected: isPlaying,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onButton;
  final bool isDark;

  const EmptyState({
    super.key,
    required this.message,
    this.buttonText,
    this.onButton,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
          if (buttonText != null && onButton != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onButton,
              icon: Icon(
                Icons.add,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              label: Text(
                buttonText!,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
