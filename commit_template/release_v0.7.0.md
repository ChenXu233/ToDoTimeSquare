# Release V0.7.0

**发布日期:** 2025-12-30

**版本号:** 0.6.6 → 0.7.0

---

## ✨ 新功能

### 音乐播放错误处理系统
- ✨ 提取 MusicCacheManager 单独管理缓存操作
- ✨ 音乐播放器添加错误视图显示 ErrorView 组件
- ✨ 新增 MusicErrorType 和 RecoveryAction 枚举分类
- ✨ 支持错误类型识别和恢复操作建议

### 待办事项功能增强
- ✨ 添加任务滑动操作菜单 (SwipeActionMenu)
- ✨ 支持左滑删除、编辑、完成等操作
- ✨ TodoProvider 新增 moveTodo 和 reorderTodos 方法
- ✨ 添加待办事项模态框及相关组件

### 国际化
- ✨ 新增 noTasksYet 字段（暂无任务提示）
- ✨ 新增 taskActions 字段（任务操作菜单标题）

---

## ♻️ 重构优化

- ♻️ 重构音乐缓存管理逻辑，委托给 MusicCacheManager
- ♻️ 添加重试指数退避机制（500ms, 1s, 2s...）
- ♻️ 优化 todo_item 组件布局

---

## 🐛 Bug 修复

- 🐛 修复 Web 平台音乐缓存和播放兼容性问题
- 🐛 修复 Web 平台音频播放兼容性问题

---

## 🔧 其他变更

- 🔧 版本升级 0.6.6 → 0.7.0
- 🔧 优化代码格式和颜色透明度计算
- 🔧 清理无用脚本文件

---

## 📦 新增文件

- `lib/providers/music_cache_manager.dart` - 音乐缓存管理器
- `lib/widgets/error/error_view.dart` - 错误视图组件
- `lib/widgets/error/action_button.dart` - 错误操作按钮
- `lib/widgets/error/error_icon.dart` - 错误图标
- `lib/widgets/error.dart` - 错误组件入口
- `lib/screens/todo/widgets/modal/swipe_action_menu.dart` - 滑动操作菜单

---

## 📝 提交记录

| 提交 | 描述 |
|:---:|------|
| `18f1ea6` | :bookmark: V0.7.0 |
| `eb4f155` | ✨ feat(todo): 添加任务滑动操作菜单与拖拽排序 |
| `c1e09a5` | ✨ feat(music): 音乐播放器添加错误视图显示 |
| `9bb1f8c` | ✨ feat(music): 音乐播放错误处理系统重构 |
| `a73aeef` | ✨ feat(i18n): 添加任务相关国际化字段 |
| `5ee2160` | ✨ feat(music): 音乐播放错误处理系统重构 |
| `b3a5646` | :sparkles: 添加待办事项模态框及相关组件 |
| `369e1c7` | :lipstick: 优化代码格式和颜色透明度计算 |
| `7ee37c4` | :bug: 修复Web平台音乐缓存和播放兼容性问题 |

---