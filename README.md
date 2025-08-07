# onanistic_coffeine

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


这个项目既有趣又富有挑战性。下面是为你的跨平台软件 **“手冲咖啡”** 制定的一份初步规划，包括技术选型、功能模块、数据分析逻辑和同步方案。它同时具有**记录**、**分析**和**引导**三大功能目标。

---

## 🧠 产品定位：

一个旨在通过记录与分析手淫行为，帮助用户理解自身生理心理节奏、优化健康习惯、避免沉迷的工具型应用。
**关键词**：健康、自律、隐私、安全、跨平台、可视化。

---

## 🧩 功能模块设计

### 1. 📅 数据记录

* 时间戳记录（支持时区）
* 类型分类（普通、色情内容驱动、自慰辅助设备等）
* 体验评分（1\~10）
* 状态记录（前情绪、后情绪、疲劳程度）
* 备注文本

> 可选：是否使用色情内容、是否有自慰辅助工具、是否伴随高潮等。

---

### 2. 📊 数据分析

* 频率图（按日/周/月统计）
* 打飞机与情绪波动关联（打完是快乐还是空虚）
* 评分趋势图（高分低频 vs 低分高频）
* 反思模块（间隔时间过短提示）
* 习惯热力图（比如某些时间段高频）

---

### 3. ⏰ 健康引导功能

* 频率警告机制（如：近3天超过5次）
* 正向强化（如：连续3天未自慰奖励勋章）
* 科普文章推送（基于时机，如连续频率偏高后推送关于多巴胺戒断的内容）

---

### 4. ☁️ 数据同步与安全

* 多端同步（加密存储 + 云同步）
* 本地离线记录支持，稍后同步
* 加密策略：使用 AES + 可选云端存储（比如 iCloud / 自建服务器 / Firebase）
* 支持账号登录（匿名UUID也可）

---

### 5. 📱 跨平台客户端

建议用下列技术栈实现：

| 平台          | 技术栈                                |
| ----------- | ---------------------------------- |
| 全平台核心       | **Tauri 2 + Vue 3 + Vite + Pinia** |
| iOS/Android | Capacitor or Tauri Mobile (实验性)    |
| 纯 Web       | 同一套代码可构建为 PWA                      |
| 数据存储        | SQLite + Prisma / IndexedDB（Web）   |

---

### 6. 🛠️ 后端同步服务（可选）

* 技术建议：Go + Gin + SQLite/PostgreSQL
* REST 或 GraphQL 接口
* Token 验证，支持匿名用户（UUID+本地密码）
* 同步策略：记录最后同步时间，按增量合并

---

## 🔐 隐私与安全

* 加密存储：本地数据加密（推荐 AES-256）
* 应用锁功能（启动需 PIN 或 Face ID）
* 日志、敏感数据默认不上传
* 支持「假账户」切换（迷惑他人用）

---

## 🧪 用户界面建议

* 简洁日历视图记录次数
* 折线图+条形图展示频率与体验
* 「冥想」或「健康提示」卡片（引导非色情放松方式）
* 可以命名每一次记录（例如“考试压力大之后”）

---

## 🧼 命名建议

* 中文名：**手冲咖啡**、**节制助手**、**自律日记**
* 英文名：**Onanistic Caffeine**, **SpankLog**, **JerkTracker**

---

## 🔮 后续可扩展功能

* 社区功能（匿名交流）
* GPT 生成引导建议或情绪分析
* Apple HealthKit / Google Fit 接入（心率、睡眠 vs 行为分析）
* 多人设备间共享（情侣记录等 🤯）

---

如果你愿意，我可以继续为你生成：

* 数据库 schema 设计（支持统计与同步）
* 初始 Vue + Tauri 项目结构模板
* 同步 API 示例（REST 或 GraphQL）
* 数据可视化的 ECharts 配置

需要我从哪一部分开始具体展开？
