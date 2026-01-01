import 'package:flutter/material.dart';
import '../../models/sample/music_track.dart';
import 'error_icon.dart';

/// 错误提示视图 - 可复用的错误展示组件（紧凑版）
///
/// 支持多种错误类型和恢复操作
class ErrorView extends StatelessWidget {
  /// 错误类型
  final MusicErrorType errorType;

  /// 错误消息
  final String message;

  /// 发生错误的曲目（可选）
  final String? trackTitle;

  /// 恢复操作建议
  final RecoveryAction recoveryAction;

  /// 是否显示重试按钮
  final bool showRetryButton;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 关闭回调
  final VoidCallback? onDismiss;

  /// 清除缓存回调
  final VoidCallback? onClearCache;

  /// 重新导入回调
  final VoidCallback? onReimport;

  /// 检查网络回调
  final VoidCallback? onCheckNetwork;

  /// 主题配置
  final bool isDark;

  /// 是否使用紧凑模式（用于小空间）
  final bool compact;

  const ErrorView({
    super.key,
    required this.errorType,
    required this.message,
    this.trackTitle,
    required this.recoveryAction,
    this.showRetryButton = true,
    this.onRetry,
    this.onDismiss,
    this.onClearCache,
    this.onReimport,
    this.onCheckNetwork,
    this.isDark = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 24.0 : 32.0;
    final padding = compact ? const EdgeInsets.all(8) : const EdgeInsets.all(12);
    final horizontalPadding = compact ? const EdgeInsets.symmetric(horizontal: 8) : const EdgeInsets.symmetric(horizontal: 12);

    return Container(
      padding: padding,
      margin: horizontalPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        color: _getColor().withAlpha(20),
        border: Border.all(
          color: _getColor().withAlpha(100),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标
          ErrorIcon(
            errorType: errorType,
            size: iconSize,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // 消息和标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getErrorTitle(),
                  style: TextStyle(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.3,
                  ),
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (trackTitle != null && !compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    '♪ $trackTitle',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 操作按钮
          if (_hasActions)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildCompactActions(),
            ),
        ],
      ),
    );
  }

  bool get _hasActions {
    switch (recoveryAction) {
      case RecoveryAction.retry:
        return showRetryButton && onRetry != null;
      case RecoveryAction.redownload:
        return onRetry != null;
      case RecoveryAction.clearCache:
        return onClearCache != null;
      case RecoveryAction.importAgain:
        return onReimport != null;
      case RecoveryAction.checkNetwork:
        return onCheckNetwork != null;
      case RecoveryAction.none:
        return onDismiss != null;
    }
  }

  Widget _buildCompactActions() {
    final buttons = <Widget>[];

    switch (recoveryAction) {
      case RecoveryAction.retry:
        if (showRetryButton && onRetry != null) {
          buttons.add(_buildIconButton(Icons.refresh, onRetry!));
        }
        break;
      case RecoveryAction.redownload:
        if (onRetry != null) {
          buttons.add(_buildIconButton(Icons.download, onRetry!));
        }
        break;
      case RecoveryAction.clearCache:
        if (onClearCache != null) {
          buttons.add(_buildIconButton(Icons.delete_outline, onClearCache!));
        }
        break;
      case RecoveryAction.importAgain:
        if (onReimport != null) {
          buttons.add(_buildIconButton(Icons.upload_file, onReimport!));
        }
        break;
      case RecoveryAction.checkNetwork:
        if (onCheckNetwork != null) {
          buttons.add(_buildIconButton(Icons.wifi, onCheckNetwork!));
        }
        break;
      case RecoveryAction.none:
        break;
    }

    if (onDismiss != null) {
      buttons.add(_buildIconButton(Icons.close, onDismiss!));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (errorType) {
      case MusicErrorType.networkError:
        return Colors.orange;
      case MusicErrorType.fileError:
        return Colors.red;
      case MusicErrorType.audioError:
        return Colors.purple;
      case MusicErrorType.playbackError:
        return Colors.amber;
      case MusicErrorType.cacheError:
        return Colors.blue;
      case MusicErrorType.unknownError:
        return Colors.grey;
    }
  }

  String _getErrorTitle() {
    switch (errorType) {
      case MusicErrorType.networkError:
        return '网络错误';
      case MusicErrorType.fileError:
        return '文件错误';
      case MusicErrorType.audioError:
        return '音频错误';
      case MusicErrorType.playbackError:
        return '播放错误';
      case MusicErrorType.cacheError:
        return '缓存错误';
      case MusicErrorType.unknownError:
        return '发生错误';
    }
  }
}

/// 错误提示 SnackBar - 轻量级错误提示
class ErrorSnackbar extends SnackBar {
  final MusicErrorType errorType;
  final String message;
  final VoidCallback? onAction;

  ErrorSnackbar({
    super.key,
    required this.errorType,
    required this.message,
    this.onAction,
  }) : super(
          content: Row(
            children: [
              ErrorIcon(
                errorType: errorType,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(errorType),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          action: onAction != null
              ? SnackBarAction(
                  label: '重试',
                  onPressed: onAction,
                )
              : null,
        );

  static String _getTitle(MusicErrorType type) {
    switch (type) {
      case MusicErrorType.networkError:
        return '网络错误';
      case MusicErrorType.fileError:
        return '文件错误';
      case MusicErrorType.audioError:
        return '音频错误';
      case MusicErrorType.playbackError:
        return '播放错误';
      case MusicErrorType.cacheError:
        return '缓存错误';
      case MusicErrorType.unknownError:
        return '发生错误';
    }
  }
}
