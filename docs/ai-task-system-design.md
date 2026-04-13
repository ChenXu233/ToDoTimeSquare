# AI 线性任务系统 + 游戏化番茄钟设计方案

> 设计目标：解决任务颗粒度太粗、依赖关系不清、hyperfocus 逃避番茄钟、缺少进度反馈的问题

---

## 一、系统愿景

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户视角的日常                            │
├─────────────────────────────────────────────────────────────────┤
│  早上打开应用，AI 已经根据你的大目标生成了今日任务链：              │
│                                                                  │
│  [✅ 复习前一天内容] → [⏳ 写引言第2段] → [🔒 做实验数据分析]     │
│                                                                  │
│  点击"开始番茄钟"，窗口退到后台，屏幕上出现一个极简悬浮球：       │
│                                                                  │
│  ┌──────────────────────────────────────────────┐                │
│  │ 写引言第2段 · 专注中 · 23:41  remaining     │                │
│  └──────────────────────────────────────────────┘                │
│                                                                  │
│  写完后，打开悬浮球，点击"完成"，AI 自动检查内容质量：            │
│  "看起来不错！但实验部分的数据可视化还需要补充图表"                │
│                                                                  │
│  下一任务自动解锁 ...                                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 二、核心问题与解决思路

| 问题 | 根源 | 解决思路 |
|------|------|----------|
| 任务太大无从下手 | 缺少子任务分解 | AI 自动拆解大任务为可执行的线性步骤 |
| 不知道任务完成没有 | 完成标准模糊 | 每个子任务绑定明确的验证规则 |
| 任务依赖关系不清 | 缺少任务图视图 | 拓扑排序 + 依赖链可视化 |
| 无视番茄钟 | 没有实时反馈 | 悬浮球游戏化进度 + AI 适时提醒 |
| hyperfocus 后自责 | 缺少正向激励 | 完成规则触发成就/奖励反馈 |

---

## 三、系统架构

### 3.1 模块关系图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Flutter App                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐    │
│  │    任务链页面     │    │    番茄钟页面     │    │    悬浮球窗口     │    │
│  │   (TaskChain)    │    │   (Pomodoro)     │    │  (FloatingBall)  │    │
│  └────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘    │
│           │                        │                        │              │
│           └────────────────────────┴────────────────────────┘              │
│                                     │                                        │
│                    ┌────────────────┴────────────────┐                     │
│                    │       共享状态管理层 (Provider)    │                     │
│                    └────────────────┬────────────────┘                     │
│                                     │                                        │
│  ┌──────────────────────────────────┴──────────────────────────────────┐   │
│  │                          核心引擎层                                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │   │
│  │  │ TaskGraph   │  │ Pomodoro    │  │ RuleEngine  │  │ Progress  │  │   │
│  │  │ Engine      │  │ Engine      │  │             │  │ Aggregator│  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘  │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                     │                                        │
│                    ┌────────────────┴────────────────┐                     │
│                    │         AI 服务层 (AIController)   │                     │
│                    └────────────────┬────────────────┘                     │
│                                     │                                        │
└─────────────────────────────────────┼────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │          外部依赖                  │
                    │  ┌───────────┐  ┌─────────────┐  │
                    │  │ AI API    │  │ 本地存储     │  │
                    │  │(Claude/   │  │(Drift DB)   │  │
                    │  │ GPT-4V)   │  │             │  │
                    │  └───────────┘  └─────────────┘  │
                    └────────────────────────────────────┘
```

### 3.2 数据流向

```
用户输入（任务目标）
      ↓
TaskGraphEngine 创建任务节点
      ↓
AIController 请求 AI 拆解子任务 + 生成完成规则
      ↓
规则存储到 CompletionRule 表
      ↓
PomodoroEngine 驱动计时 + 状态更新
      ↓
RuleEngine 持续验证规则（文件监控 / 剪贴板 / AI检查）
      ↓
验证通过 → 任务完成 → 下一任务解锁 → FloatingBall 欢呼动画
      ↓
ProgressAggregator 计算全局进度 → UI 刷新
```

---

## 四、详细模块设计

### 4.1 TaskGraph Engine（任务图引擎）

**职责**：
- 管理任务节点及其依赖关系
- 提供拓扑排序，确定任务执行顺序
- 状态传播：完成一个任务，自动解锁依赖它的下一个任务

**核心算法**：
```
1. Kahn's Algorithm（拓扑排序）
   - 计算所有节点的入度
   - 从入度为 0 的节点开始（根任务）
   - 每完成一个任务，将其下游任务的入度 -1
   - 入度变为 0 时，任务解锁

2. 状态机转换
   blocked → ready → in_progress → completed
   (有依赖未完成) (依赖已全部完成) (正在做) (验证通过)
```

**API 设计**：
```dart
class TaskGraphEngine {
  // 添加任务节点
  Future<TaskNode> addTask(String title, List<String> dependencies);

  // AI 拆解任务（调用 AI 服务）
  Future<List<TaskNode>> decomposeTask(String taskId, String aiPrompt);

  // 完成任务（触发验证）
  Future<bool> completeTask(String taskId);

  // 获取可执行任务列表
  List<TaskNode> getReadyTasks();

  // 获取任务链视图
  List<TaskNode> getTaskChain();
}
```

### 4.2 RuleEngine（规则引擎）

**职责**：
- 管理每个任务的完成规则
- 持续监控规则触发条件
- 验证任务是否满足完成条件

**支持的规则类型**：

| 规则类型 | 触发条件 | 验证方式 | 示例 |
|----------|----------|----------|------|
| `manual` | 用户手动确认 | 点击"完成"按钮 | "你觉得写好了就点我" |
| `fileExists` | 文件被创建/修改 | 文件系统监控 | "检测到 summary.pdf 生成" |
| `clipboardMatch` | 剪贴板包含特定内容 | 监听剪贴板 | "复制了 arXiv 链接" |
| `urlVisit` | 访问了特定 URL | 浏览器历史 / 主动上报 | "访问了 GitHub PR 页面" |
| `aiCheck` | AI 检查内容质量 | 调用 AI API | "AI 评价：实验数据充分" |
| `timerCount` | 累计番茄钟数达到 N | PomodoroEngine 计数 | "完成 4 个番茄钟" |

**验证流程**：
```
RuleEngine.watch()
      ↓
┌─────────────────────────────────────────────┐
│  规则类型        监控机制                    │
│  ─────────────────────────────────────────  │
│  manual        → 等待用户点击               │
│  fileExists    → fs.watch (5s 轮询)         │
│  clipboardMatch → Clipboard.setListener     │
│  urlVisit      → 用户点击上报 / 历史查询     │
│  aiCheck       → 请求 AI API               │
│  timerCount    → PomodoroEngine 广播        │
└─────────────────────────────────────────────┘
      ↓
  验证通过 → emit TaskCompletedEvent
      ↓
  TaskGraphEngine.updateStatus()
      ↓
  FloatingBall 显示成就动画
```

### 4.3 AIController（AI 控制器）

**职责**：
- 与 AI 服务通信（Claude / GPT-4V）
- 解析 AI 返回的任务拆解结果
- 解析 AI 返回的内容质量评价

**Prompt 设计**：

**任务拆解 Prompt**：
```
你是一个任务管理助手。用户有一个大任务需要拆解成线性步骤。

任务：{user_task_description}

请按以下 JSON 格式返回拆解结果：
{
  "subtasks": [
    {
      "title": "子任务标题",
      "estimated_minutes": 预估分钟数,
      "completion_rule": {
        "type": "manual|fileExists|clipboardMatch|aiCheck|timerCount",
        "description": "用中文描述完成这个任务的标准"
      }
    }
  ],
  "chain_hint": "任务链的整体思路说明"
}
```

**内容质量检查 Prompt**：
```
你是一个严格的任务评审专家。请判断用户的任务完成质量。

任务：{task_title}
任务要求：{task_description}
用户产出：{user_content}

请返回：
{
  "passed": true/false,
  "score": 0-100,
  "feedback": "中文评价和建议"
}
```

**API 调用策略**：
- 使用流式响应（stream），实时显示 AI 分析过程
- 缓存已分析的任务，避免重复调用
- 本地模型优先（LlamaEdge），降低 API 成本

### 4.4 FloatingBall（悬浮球）

**职责**：
- 在桌面前台常驻显示当前任务状态
- 极简文字风格（类似音乐歌词）
- 提供快速操作入口

**窗口配置**：
```dart
WindowConfig {
  alwaysOnTop: true,
  transparent: true,
  frameless: true,
  resizable: false,
  size: [320, ~60],  // 固定宽度，高度自适应
  position: 屏幕右下角（可拖拽）
}
```

**显示内容**：
```
{task_title} · {status} · {time_remaining}
[▶ 继续] [⏸ 休息] [✓ 完成]
```

**状态文案**：
| 状态 | 文案示例 |
|------|----------|
| 专注中 | "写引言第2段 · 专注中 · 23:41" |
| 休息中 | "休息 · 5:00 remaining" |
| 任务完成 | "✅ 完成！下一任务：做实验数据分析" |
| AI 提醒 | "还在写引言吗？还剩 5 分钟哦" |
| 成就解锁 | "🎉 连续 3 个番茄钟！保持得好" |

**交互**：
- 点击球体：聚焦主窗口 + 跳转到对应任务
- 按钮点击：快速操作（完成/暂停/继续）
- 右键菜单：设置 / 暂停悬浮球 / 关闭

### 4.5 PomodoroEngine（番茄钟引擎）

**职责**：
- 独立运行，不依赖 UI
- 支持后台计时
- 与 TaskGraph 联动

**解耦设计**：
```dart
// 使用 Isolate 分离计时逻辑
class PomodoroEngine {
  // 主 isolate 调用
  Future<void> startPomodoro(String taskId);

  // Isolate 内部计时，不受主 UI 阻塞
  // 完成时发送通知
  // 更新 TaskGraphEngine 状态
}
```

**番茄钟结束时的 AI 介入**：
```
番茄钟结束
      ↓
RuleEngine 检查任务完成规则
      ↓
┌─────────────────────────────┐
│  规则类型       AI 介入      │
│  ─────────────────────────  │
│  manual        → AI 询问进度 │
│  aiCheck       → AI 自动检查 │
│  timerCount    → 自动计数   │
└─────────────────────────────┘
      ↓
悬浮球显示反馈 + 决定是否自动解锁下一任务
```

---

## 五、数据模型

### 5.1 数据库 Schema（Drift）

```dart
// 任务节点表
class TaskNodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get status => integer()(); // 0=blocked, 1=ready, 2=in_progress, 3=completed
  TextColumn get dependencies => text()(); // JSON array of task IDs
  TextColumn get completionRuleJson => text().nullable()();
  TextColumn get submissionTarget => text().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

// 任务链表（顶层任务）
class TaskChains extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get progress => integer()(); // 0-100
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// 番茄钟记录表
class PomodoroRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskNodeId => integer().nullable().references(TaskNodes, #id)();
  IntColumn get duration => integer()(); // seconds
  IntColumn get completedAt => dateTime()();
  BoolColumn get wasCompleted => boolean()();
}

// AI 任务分解缓存
class TaskDecompositionCache extends Table {
  TextColumn get inputHash => text()(); // MD5 of original task text
  TextColumn get decompositionJson => text()();
  DateTimeColumn get createdAt => dateTime()();
}
```

### 5.2 内存数据结构

```dart
// 任务节点
class TaskNode {
  final String id;
  final String title;
  TaskStatus status;
  final List<String> dependencies;
  final CompletionRule? rule;
  final String? submissionTarget;
  final int? estimatedMinutes;

  // 计算属性
  bool get isBlocked => status == TaskStatus.blocked;
  bool get isReady => status == TaskStatus.ready;
  bool get isCompleted => status == TaskStatus.completed;
}

// 完成规则
class CompletionRule {
  final RuleType type;
  final String description; // 展示给用户的描述
  final String? param; // 规则参数（如文件路径、正则表达式）
  final dynamic expectedValue; // 期望值
}

// 任务链（聚合视图）
class TaskChain {
  final String id;
  final String title;
  final List<TaskNode> nodes;
  final int totalProgress; // 0-100

  List<TaskNode> get readyNodes => nodes.where((n) => n.isReady).toList();
  List<TaskNode> get completedNodes => nodes.where((n) => n.isCompleted).toList();
  TaskNode? get currentNode => nodes.firstWhere((n) => n.isReady, orElse: () => null);
}
```

---

## 六、实现步骤（Phase 1 - 3）

### Phase 1：核心引擎（2-3 周）

**目标**：TaskGraph Engine + 基础任务链 UI

| Step | 任务 | 产出 |
|------|------|------|
| 1.1 | 创建 `TaskNode` 和 `TaskChain` 数据模型 | `models/task_graph/` |
| 1.2 | 实现 Kahn's Algorithm 拓扑排序 | `services/task_graph_engine.dart` |
| 1.3 | 实现状态机转换逻辑 | 同上 |
| 1.4 | 创建任务链页面 UI | `screens/task_chain/` |
| 1.5 | 创建子任务添加/编辑 UI | `screens/task_chain/widgets/` |
| 1.6 | 实现任务依赖关系可视化 | 同上 |

### Phase 2：AI 集成（2 周）

**目标**：AIController + 任务拆解 + 验证规则

| Step | 任务 | 产出 |
|------|------|------|
| 2.1 | 创建 AIController 服务 | `services/ai_controller.dart` |
| 2.2 | 实现 Claude/GPT API 调用封装 | `services/ai_provider.dart` |
| 2.3 | 实现任务拆解 Prompt + 解析 | AIController 方法 |
| 2.4 | 创建 AI 拆解对话框 UI | `screens/task_chain/ai_decompose_dialog.dart` |
| 2.5 | 创建规则配置 UI | `screens/task_chain/rule_config.dart` |

### Phase 3：番茄钟 + 悬浮球（2 周）

**目标**：PomodoroEngine 解耦 + FloatingBall

| Step | 任务 | 产出 |
|------|------|------|
| 3.1 | 重构 PomodoroProvider 为 PomodoroEngine | `services/pomodoro_engine.dart` |
| 3.2 | 使用 Isolate 分离计时逻辑 | 同上 |
| 3.3 | 配置 window_manager | `main.dart` |
| 3.4 | 创建悬浮球页面 | `screens/floating_ball/` |
| 3.5 | 实现悬浮球游戏化文案系统 | `services/motivation_messages.dart` |
| 3.6 | 实现悬浮球动画（淡入淡出） | `screens/floating_ball/` |

### Phase 4：规则引擎（1-2 周）

**目标**：RuleEngine + 验证触发

| Step | 任务 | 产出 |
|------|------|------|
| 4.1 | 实现 fileExists 监控 | `services/rules/file_watcher.dart` |
| 4.2 | 实现 clipboardMatch 监控 | `services/rules/clipboard_watcher.dart` |
| 4.3 | 实现 timerCount 规则 | `services/rules/timer_rule.dart` |
| 4.4 | 实现 aiCheck 规则 | `services/rules/ai_check_rule.dart` |
| 4.5 | 创建规则触发通知 UI | `screens/floating_ball/rule_notification.dart` |
| 4.6 | 集成 AI 提醒 Prompt 系统 | `services/ai_controller.dart` |

---

## 七、关键设计决策

### 7.1 为什么用 Kahn's Algorithm 而不是 DFS？

- Kahn's Algorithm 产生**广度优先**的任务顺序，更符合线性执行直觉
- DFS 递归可能导致任务链顺序不稳定
- Kahn's Algorithm 更容易处理"多条并行任务链"的场景

### 7.2 为什么规则引擎轮询而不是事件驱动？

- Flutter Desktop 缺乏原生的文件系统 Watch API
- `watcher` package 使用轮询实现（1-5s 间隔）
- 事件驱动需要平台特定实现（Win32 API / FSEvents），增加复杂度
- 对于"任务完成检测"场景，5s 延迟是可接受的

### 7.3 为什么悬浮球用文字而非图形？

- 用户明确选择极简文字风格
- 文字信息密度更高，一眼获取关键信息
- 实现简单，避免图形资源设计成本
- 未来可扩展主题切换（文字 ↔ 像素 ↔ 扁平）

### 7.4 为什么 AI 调用用缓存？

- 同一任务文本的拆解结果应该稳定
- 避免重复 API 调用，节省成本
- 使用 MD5(input) 作为缓存 key

---

## 八、风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| AI 拆解质量不稳定 | 任务链不合理 | 用户可手动调整 AI 拆解结果 |
| 规则误判（文件未真正写完） | 虚假完成 | AI Check 作为高权重验证 |
| 悬浮球占用屏幕空间 | 用户分心 | 可最小化/隐藏悬浮球 |
| 番茄钟后台计时不准 | 记录失真 | 使用 Isolate 隔离，UI 刷新不影响计时 |
| 依赖循环（用户创建了循环依赖） | 系统崩溃 | 创建时检测环，无法保存 |

---

## 九、测试策略

### 单元测试
- TaskGraphEngine 的拓扑排序
- 状态机转换逻辑
- CompletionRule 的验证计算

### 集成测试
- 任务创建 → 拆解 → 执行 → 完成全流程
- 番茄钟计时与任务状态联动
- 规则引擎触发与状态更新

### E2E 测试
- 用户打开应用 → AI 拆解 → 番茄钟执行 → 悬浮球反馈
- 验证完整的用户故事

---

## 十、后续扩展方向

1. **数据统计**：任务完成时间分布、番茄钟效率分析
2. **成就系统**：连续完成任务解锁徽章
3. **多端同步**：任务链云端同步（复用现有 sync_service）
4. **本地模型**：LlamaEdge 替代云端 AI，完全离线
5. **插件系统**：自定义规则类型

---

*文档版本：v1.0*
*最后更新：2026-04-13*
