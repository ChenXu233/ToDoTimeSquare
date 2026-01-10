# ToDoTimeSquare Release History

---

## 📦 V0.8.0

**发布日期:** 2026-01-10

**版本号:** 0.7.3 → 0.8.0

---

## ✨ 新功能

### 用户认证
- :sparkles: feat(auth): 实现用户认证系统
- :sparkles: feat(ui): 添加用户登录功能

### 标签系统
- :sparkles: feat(tags): 实现任务标签系统功能
- :sparkles: feat(tags): 重构标签选择器 UI 为响应式布局

### 数据导出
- :sparkles: feat(export): 添加数据导出功能

### 国际化
- :globe_with_meridians: feat(i18n): 实现国际化框架
- :globe_with_meridians: feat(i18n): 添加中英文资源文件

### 后端服务
- :sparkles: feat(backend): 新增 FastAPI 后端服务
- :sparkles: feat(sync): 恢复同步功能核心文件
- :sparkles: feat(sync): 恢复同步记录模型
- :sparkles: feat(settings): 新增设置页面和同步功能

---

## ♻️ 重构优化

- :recycle: refactor: 代码质量优化
- ✨ feat(ui): 重构登录注册界面，优化输入框和按钮样式
- ✨ feat(ui): 优化 TaskTray 展开动画效果

---

## 🐛 Bug 修复

- :bug: fix(backend): 修复 bcrypt 兼容性并清理依赖
- 🐛 fix(ui): 优化滑动阈值和按钮样式

---

## 🔧 其他变更

- :fire: chore: 移除 Python 后端代码

---

## 📦 新增文件

- `backend/` - FastAPI 后端服务
- `lib/features/auth/` - 用户认证模块
- `lib/features/tags/` - 标签系统
- `lib/features/export/` - 数据导出功能
- `lib/features/settings/` - 设置页面
- `lib/i18n/` - 国际化资源
- `l10n.yaml` - 国际化配置

---

## 📝 提交记录

| 提交 | 描述 |
|:---:|------|
| `92ab4e8` | :bug: fix(backend): 修复 bcrypt 兼容性并清理依赖 |
| `c29088b` | :sparkles: feat(sync): 恢复同步记录模型 |
| `1dda48a` | :sparkles: feat(sync): 恢复同步功能核心文件 |
| `ddd93aa` | :sparkles: feat(backend): 新增 FastAPI 后端服务 |
| `1482457` | :sparkles: feat(settings): 新增设置页面和同步功能 |
| `b7db202` | :globe_with_meridians: feat(i18n): 添加中英文资源文件 |
| `a98ce70` | :globe_with_meridians: feat(i18n): 实现国际化框架 |
| `3d690d9` | :fire: chore: 移除 Python 后端代码 |
| `391859e` | ✨ feat(ui): 重构登录注册界面，优化输入框和按钮样式 |
| `690ff0a` | ✨ feat(ui): 优化 TaskTray 展开动画效果 |
| `619cb8c` | 🐛 fix(ui): 优化滑动阈值和按钮样式 |
| `76eabed` | ✨ feat(tags): 重构标签选择器 UI 为响应式布局 |
| `68b748d` | ✨ feat(tags): 实现任务标签系统功能 |
| `7f118c5` | ♻️ refactor: 代码质量优化 |
| `a0c9966` | ✨ feat(export): 添加数据导出功能 |
| `becf6eb` | ✨ feat(ui): 添加用户登录功能 |
| `75edfd7` | ✨ feat(auth): 实现用户认证系统 |

---
