// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'i18n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class APPi18nZh extends APPi18n {
  APPi18nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '待办事项时间广场';

  @override
  String get welcomeMessage => '欢迎使用待办事项时间广场';

  @override
  String get addTask => '添加任务';

  @override
  String get taskName => '任务名称';

  @override
  String get taskDescription => '任务描述';

  @override
  String get taskDueDate => '截止日期';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get completed => '已完成';

  @override
  String get allTasks => '所有任务';

  @override
  String get todayTasks => '今日任务';

  @override
  String get upcomingTasks => '即将到来';

  @override
  String get settings => '设置';

  @override
  String get darkMode => '暗黑模式';

  @override
  String get language => '语言';

  @override
  String get notification => '通知';

  @override
  String get about => '关于';

  @override
  String get help => '帮助';
}
