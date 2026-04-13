import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/i18n.dart';
import '../../../models/dtos/sync_dto.dart';
import '../../../services/sync_service.dart';

/// 冲突解决对话框
class ConflictResolveDialog extends StatefulWidget {
  final ConflictInfo conflict;
  final String accessToken;

  const ConflictResolveDialog({
    super.key,
    required this.conflict,
    required this.accessToken,
  });

  @override
  State<ConflictResolveDialog> createState() => _ConflictResolveDialogState();
}

class _ConflictResolveDialogState extends State<ConflictResolveDialog> {
  bool _resolving = false;
  bool _keepLocal = true;

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final localTime = DateTime.fromMillisecondsSinceEpoch(widget.conflict.localTimestamp);
    final serverTime = DateTime.fromMillisecondsSinceEpoch(widget.conflict.serverTimestamp);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(i18n.resolveConflict),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 冲突信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i18n.entityType}: ${_getEntityTypeName(widget.conflict.entityType)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('ID: ${widget.conflict.entityId}'),
                    const SizedBox(height: 4),
                    Text(
                      '${i18n.localVersion}: ${widget.conflict.localVersion} | ${i18n.serverVersion}: ${widget.conflict.serverVersion}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 数据对比
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 本地数据
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.blue : Colors.blue[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.computer, size: 16, color: isDark ? Colors.blue : Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text(
                                i18n.localData,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.blue : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${i18n.modifiedAt}: ${_formatDateTime(localTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._buildDataRows(widget.conflict.localData),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 服务器数据
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.green : Colors.green[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cloud, size: 16, color: isDark ? Colors.green : Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                i18n.serverData,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.green : Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${i18n.modifiedAt}: ${_formatDateTime(serverTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._buildDataRows(widget.conflict.serverData),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 选择保留哪个版本
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i18n.resolveChoice, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioGroup<bool>(
                      groupValue: _keepLocal,
                      onChanged: (value) {
                        setState(() {
                          _keepLocal = value ?? true;
                        });
                      },
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            title: Text(i18n.keepLocalVersion),
                            subtitle: Text(i18n.keepLocalVersionDesc),
                            value: true,
                          ),
                          RadioListTile<bool>(
                            title: Text(i18n.keepServerVersion),
                            subtitle: Text(i18n.keepServerVersionDesc),
                            value: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resolving ? null : () => Navigator.pop(context),
          child: Text(i18n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _resolving ? null : _resolveConflict,
          icon: _resolving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(i18n.resolve),
          style: ElevatedButton.styleFrom(
            backgroundColor: _keepLocal ? Colors.blue : Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDataRows(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return [Text('(empty)', style: TextStyle(color: Colors.grey[500]))];
    }
    return data.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w500)),
            Expanded(
              child: Text(e.value?.toString() ?? 'null'),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getEntityTypeName(String entityType) {
    switch (entityType) {
      case 'todo':
        return 'Todo';
      case 'focus_record':
        return 'Focus Record';
      case 'habit':
        return 'Habit';
      case 'habit_log':
        return 'Habit Log';
      case 'tag':
        return 'Tag';
      case 'tag_relation':
        return 'Tag Relation';
      default:
        return entityType;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resolveConflict() async {
    setState(() {
      _resolving = true;
    });

    final syncService = context.read<SyncService>();
    try {
      await syncService.resolveConflict(
        widget.conflict.entityType,
        widget.conflict.entityId,
        _keepLocal,
        widget.accessToken,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('SyncException: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _resolving = false;
        });
      }
    }
  }
}

/// 显示冲突解决对话框
Future<bool?> showConflictResolveDialog(
  BuildContext context,
  ConflictInfo conflict,
  String accessToken,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConflictResolveDialog(
      conflict: conflict,
      accessToken: accessToken,
    ),
  );
}
