import 'package:flutter/material.dart';
import '../../../i18n/i18n.dart';
import '../../../models/export/export_config.dart';
import '../../../models/database/app_database.dart';
import '../../../services/data_export_service.dart';
import '../../../widgets/glass/glass_container.dart';

/// 导出数据对话框
class ExportDataDialog extends StatefulWidget {
  final AppDatabase database;

  const ExportDataDialog({super.key, required this.database});

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  ExportFormat _format = ExportFormat.json;
  final Set<ExportDataType> _selectedTypes = {
    ExportDataType.todos,
    ExportDataType.focusRecords,
    ExportDataType.habits,
    ExportDataType.habitLogs,
  };
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  String? _exportStatus;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        color: _isDark ? Colors.black : Colors.white,
        opacity: 0.15,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  i18n.exportData,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 数据类型选择
            Text(
              i18n.exportDataTypes,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildDataTypeSelector(i18n),

            const SizedBox(height: 20),

            // 格式选择
            Text(
              i18n.exportFormat,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildFormatSelector(i18n),

            const SizedBox(height: 20),

            // 时间范围
            Text(
              i18n.exportDateRange,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildDateRangeSelector(i18n),

            // 状态显示
            if (_exportStatus != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _exportStatus!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isExporting ? null : () => Navigator.pop(context),
                  child: Text(i18n.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isExporting ? null : _exportData,
                  child: _isExporting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(i18n.export),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeSelector(APPi18n i18n) {
    final typeLabels = {
      ExportDataType.todos: i18n.allTasks,
      ExportDataType.focusRecords: i18n.pomodoroTitle,
      ExportDataType.habits: i18n.habitTracking,
      ExportDataType.habitLogs: i18n.checkIn,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExportDataType.values.map((type) {
        final isSelected = _selectedTypes.contains(type);
        return FilterChip(
          label: Text(typeLabels[type] ?? type.name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildFormatSelector(APPi18n i18n) {
    return Row(
      children: [
        Expanded(
          child: _buildFormatOption(
            'JSON',
            ExportFormat.json,
            i18n.exportFormatJson,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFormatOption(
            'CSV',
            ExportFormat.csv,
            i18n.exportFormatCsv,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatOption(
    String formatName,
    ExportFormat format,
    String description,
  ) {
    final isSelected = _format == format;
    return GestureDetector(
      onTap: _isExporting ? null : () => setState(() => _format = format),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withAlpha(((0.3) * 255).round()),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withAlpha(100)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  formatName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(APPi18n i18n) {
    return Row(
      children: [
        Expanded(
          child: _buildDatePicker(
            i18n.startDate,
            _startDate,
            (date) => setState(() => _startDate = date),
            _isExporting,
            i18n,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDatePicker(
            i18n.endDate,
            _endDate,
            (date) => setState(() => _endDate = date),
            _isExporting,
            i18n,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
    bool disabled,
    APPi18n i18n,
  ) {
    final notSetText = i18n.notSet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: disabled
              ? null
              : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: value ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    onChanged(date);
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withAlpha(((0.3) * 255).round()),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: value == null ? Colors.grey : null,
                ),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
                      : notSetText,
                  style: TextStyle(
                    color: value == null ? Colors.grey : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    if (_selectedTypes.isEmpty) {
      _showError(APPi18n.of(context)!.exportNoDataTypeSelected);
      return;
    }

    setState(() {
      _isExporting = true;
      _exportStatus = APPi18n.of(context)!.exportPreparing;
    });

    final config = ExportConfig(
      format: _format,
      dataTypes: _selectedTypes.toList(),
      startDate: _startDate,
      endDate: _endDate,
    );

    final service = DataExportService(db: widget.database);
    final result = await service.export(config);

    setState(() {
      _isExporting = false;
      _exportStatus = null;
    });

    if (mounted) {
      if (result.success) {
        _showSuccess(
          APPi18n.of(context)!.exportSuccess(
            result.recordCount,
            result.filePath ?? '',
          ),
        );
        Navigator.pop(context);
      } else {
        _showError(result.error ?? APPi18n.of(context)!.errorUnknown);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// 显示导出对话框的便捷方法
Future<void> showExportDataDialog(BuildContext context, AppDatabase database) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ExportDataDialog(database: database),
  );
}
