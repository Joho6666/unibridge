# 参考项目研究分析（Reference Analysis）

> 研究日期：2026-08-17。以下四个开源项目均已在 GitHub 实际访问确认存在。

## 项目 A：Prakashchandra-007/humbble

- **确认存在**：是（~70 stars，MIT，React Native + Expo + TypeScript）。
- **技术栈**：React Native / Expo（expo-router 目录式路由），后端建议 Firebase 或自选；含 `DB/` 目录、`app/`、`components/`、`constants/`、`hooks/`。
- **核心功能**：Swipe / Match / Chat、可定制匹配算法、隐私优先（不追踪）。
- **值得借鉴**：
  - `app/` + `components/` + `hooks/` + `constants/` 的分层 —— 对应到我们的 Next.js App Router 结构。
  - 把 Swipe 卡片交互做成独立组件（deck + card + gesture 分离）。
- **不适合我们**：
  - Firebase 作为后端（我们要 PostgreSQL + RLS + 强关系查询，Firebase 的嵌套文档模型不适合"共同兴趣/语言互补"这类关系运算）。
  - React Native 壳（我们第一版是响应式 Web/PWA）。

## 项目 B：helloharendra/Complete-Dating-App

- **确认存在**：是（~30 stars，MIT）。README 宣称 Flutter + FastAPI + PostgreSQL + Redis + Socket.IO，Enterprise 版含 AI 推荐 / Icebreaker / 高级分析。
- **值得借鉴**：
  - 领域模型划分：User / Preference / Like / Match / Conversation / Message。
  - Redis 缓存热数据 + WebSocket 房间式聊天（对应我们用 Supabase Realtime channel per conversation）。
  - AI Icebreaker 作为独立服务模块（我们抽象为 `AIProvider` 接口）。
- **不适合我们**：
  - 双仓库 Flutter+FastAPI 运维复杂；README 与实际目录不完全一致，代码参考价值有限。
  - Redis 在我们的规模下不必要 —— Supabase Postgres + Realtime 已覆盖。

## 项目 C：dgewe/Tinder-App-Flutter

- **确认存在**：是（~183 stars，Flutter + Firebase，仅 Android 测试）。
- **价值**：最简 Dating App 数据模型的教学样本：
  - `User`（图片、bio、偏好）
  - `Like`（from → to，方向性，记录 pass/like）
  - `Match`（双向 Like 后创建，双方引用同一 match id）
  - `Conversation` + `Message`（挂在 match 下，含时间戳）
- **值得借鉴**：Like 保持单向记录、Match 是派生实体 —— 我们照此建模，并额外加 `super_like`(=Say Hi) 与 pass/skip 区分。
- **不适合我们**：Firestore 文档型建模、无 RLS 概念。

## 项目 D：phamtoquyen/Language-Exchange-Matchmaker

- **确认存在**：是（132 commits，Node/Express + React + MySQL/Sequelize + Socket.IO + Redux，面向英语/韩语交换）。
- **值得借鉴**：
  - 用户同时声明 **native language** 与 **learning languages**，匹配本质是"我学的 = 你母语，反之亦然"的**互补配对**，而不是相似度配对 —— 这是 UniBridge 匹配算法的核心思想。
  - Friends/Dashboard 概念对应我们的 Matches 列表。
- **不适合我们**：
  - 只支持两种语言的硬编码配对；我们要任意多语言 + CEFR 等级（A1~C2/Native）。
  - Sequelize + MySQL；我们用 Supabase Postgres。
  - README 自述存在聊天需刷新等 bug —— Socket.IO 手工管理对我们没必要。

## 结论：我们最终采用的架构

| 维度 | 决策 | 来源 |
|---|---|---|
| 数据模型 | User/Profile/Like/Match/Conversation/Message 关系模型（C），扩展 language 互补字段（D） | C + D |
| 匹配 | 可解释打分制（语言互补 30 / 共同兴趣 20 / 目标契合 20 / 距离 15 / 同校同龄 10 / 活跃 5），纯函数可单测 | D 思想 + 自研 |
| 后端 | Next.js Server Actions + API Routes，Supabase (Postgres/Auth/Storage/Realtime)，不用独立后端服务 | 替代 A/B 的 Firebase/FastAPI |
| 实时聊天 | Supabase Realtime（postgres_changes 订阅 messages + broadcast typing） | 替代 B/D 的 Socket.IO |
| AI | `AIProvider` 接口 + OpenAI 兼容实现（可接 GLM/OpenAI 等）+ 无 Key 时的模板降级 | B 的 Icebreaker 思想 |
| 客户端 | Next.js App Router 响应式 Web/PWA，移动优先 + 底部导航 | A 的组件分层 |
