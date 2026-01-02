import 'package:drift/drift.dart';

/// 标签类型枚举
enum TagType {
  color,   // 颜色分类标签
  project, // 项目分类标签
  context, // 场景分类标签
  custom,  // 自定义标签
}

/// 标签表定义
class TaskTags extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('local'))();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text()(); // Hex color string, e.g., "#FF5722"
  IntColumn get type => integer()(); // 0:color, 1:project, 2:context, 3:custom
  TextColumn get icon => text().nullable()();
  BoolColumn get isPreset => boolean().withDefault(const Constant(false))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get indexes => [
        {userId},
        {type},
      ];
}
