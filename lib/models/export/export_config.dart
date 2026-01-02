/// 导出格式枚举
enum ExportFormat {
  json,
  csv,
}

/// 导出数据类型枚举
enum ExportDataType {
  todos,
  focusRecords,
  habits,
  habitLogs,
}

/// 导出配置类
class ExportConfig {
  /// 导出格式
  final ExportFormat format;

  /// 导出的数据类型列表
  final List<ExportDataType> dataTypes;

  /// 开始时间（可选，为 null 表示不限制）
  final DateTime? startDate;

  /// 结束时间（可选，为 null 表示不限制）
  final DateTime? endDate;

  ExportConfig({
    required this.format,
    required this.dataTypes,
    this.startDate,
    this.endDate,
  });

  /// 是否包含所有数据
  bool get includesAllData => startDate == null && endDate == null;

  /// 验证配置是否有效
  bool validate() {
    if (dataTypes.isEmpty) {
      return false;
    }
    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      return false;
    }
    return true;
  }

  ExportConfig copyWith({
    ExportFormat? format,
    List<ExportDataType>? dataTypes,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ExportConfig(
      format: format ?? this.format,
      dataTypes: dataTypes ?? this.dataTypes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// 导出结果
class ExportResult {
  /// 是否成功
  final bool success;

  /// 文件路径
  final String? filePath;

  /// 错误信息
  final String? error;

  /// 导出的记录数
  final int recordCount;

  ExportResult({
    required this.success,
    this.filePath,
    this.error,
    this.recordCount = 0,
  });

  factory ExportResult.success(String filePath, int recordCount) {
    return ExportResult(
      success: true,
      filePath: filePath,
      recordCount: recordCount,
    );
  }

  factory ExportResult.failure(String error) {
    return ExportResult(
      success: false,
      error: error,
    );
  }
}
