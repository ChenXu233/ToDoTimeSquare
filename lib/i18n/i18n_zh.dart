// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'i18n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class APPi18nZh extends APPi18n {
  APPi18nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Time ToDo Square';

  @override
  String get welcomeMessage => '欢迎使用Time ToDo Square';

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
  String get pomodoroTitle => '番茄钟';

  @override
  String get start => '开始';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get reset => '重置';

  @override
  String get focusTime => '专注时间';

  @override
  String get shortBreak => '短休息';

  @override
  String get longBreak => '长休息';

  @override
  String get pomodoroStatusFocus => '专注中';

  @override
  String get pomodoroStatusShortBreak => '短休息中';

  @override
  String get pomodoroStatusLongBreak => '长休息中';

  @override
  String get help => '帮助';

  @override
  String get importance => '重要性';

  @override
  String get duration => '时长';

  @override
  String get startTime => '开始时间';

  @override
  String get notSet => '未设置';

  @override
  String get low => '低';

  @override
  String get medium => '中';

  @override
  String get high => '高';

  @override
  String get pleaseEnterTitle => '请输入标题';

  @override
  String get pomodoroSettings => '番茄钟设置';

  @override
  String get pomodoroInfo => '番茄工作法';

  @override
  String get pomodoroInfoContent =>
      '番茄工作法使用定时器将工作分解为间隔，通常为25分钟，中间有短暂的休息。本应用将其简化为专注和短休息的循环。';

  @override
  String get homeMessage => '专注. 组织. 实现.';

  @override
  String get alarmSound => '提示音';
}
