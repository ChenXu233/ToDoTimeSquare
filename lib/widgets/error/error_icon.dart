import 'package:flutter/material.dart';
import '../../models/sample/music_track.dart';

/// 错误图标组件 - 根据错误类型显示对应的图标
class ErrorIcon extends StatelessWidget {
  /// 错误类型
  final MusicErrorType errorType;

  /// 图标大小
  final double size;

  /// 是否使用深色主题
  final bool isDark;

  /// 自定义颜色（覆盖默认颜色）
  final Color? customColor;

  const ErrorIcon({
    super.key,
    required this.errorType,
    this.size = 32,
    this.isDark = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getBackgroundColor().withAlpha(30),
        border: Border.all(
          color: _getColor().withAlpha(100),
          width: 2,
        ),
      ),
      child: Icon(
        _getIcon(),
        size: size * 0.6,
        color: customColor ?? _getColor(),
      ),
    );
  }

  IconData _getIcon() {
    switch (errorType) {
      case MusicErrorType.networkError:
        return Icons.wifi_off;
      case MusicErrorType.fileError:
        return Icons.insert_drive_file;
      case MusicErrorType.audioError:
        return Icons.music_off;
      case MusicErrorType.playbackError:
        return Icons.pause_circle; // 使用 pause_circle 作为替代
      case MusicErrorType.cacheError:
        return Icons.storage;
      case MusicErrorType.unknownError:
        return Icons.error_outline;
    }
  }

  Color _getColor() {
    if (customColor != null) return customColor!;

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

  Color _getBackgroundColor() {
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
}

/// 加载状态图标
class LoadingIcon extends StatelessWidget {
  final double size;
  final bool isDark;
  final Color? customColor;

  const LoadingIcon({
    super.key,
    this.size = 32,
    this.isDark = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          customColor ?? (isDark ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }
}

/// 成功状态图标
class SuccessIcon extends StatelessWidget {
  final double size;
  final bool isDark;
  final Color? customColor;

  const SuccessIcon({
    super.key,
    this.size = 32,
    this.isDark = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withAlpha(30),
        border: Border.all(
          color: (customColor ?? Colors.green).withAlpha(100),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check_circle,
        size: size * 0.6,
        color: customColor ?? Colors.green,
      ),
    );
  }
}
