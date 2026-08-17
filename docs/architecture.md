# UniBridge 技术架构

## 1. 总体架构

```
┌─────────────────────────────────────────────────────────┐
│ Next.js 15 App Router (TypeScript, 响应式 Web / PWA)     │
│  - Server Components: 数据获取、会话                      │
│  - Client Components: 交互(swipe/聊天输入)                │
│  - Server Actions / Route Handlers: 写操作               │
├─────────────────────────────────────────────────────────┤
│ 应用层 lib/                                              │
│  lib/supabase/{client,server,admin,storage}              │
│  lib/matching/   可解释打分（纯函数，vitest 单测）         │
│  lib/ai/         AIProvider 接口 + OpenAI 兼容 + 模板降级  │
│  lib/i18n/       next-intl 封装（cookie locale）          │
│  lib/validation/ Zod schemas（前后端共用）                │
│  lib/data/       查询层（discover/messages/moments/events）│
│  lib/actions/    Server Actions（likes/matches/posts…）   │
├─────────────────────────────────────────────────────────┤
│ Supabase（本地 Docker 或云）                              │
│  Postgres + RLS │ Auth(GoTrue) │ Realtime │ Storage      │
└─────────────────────────────────────────────────────────┘
```

- **无独立后端服务**：Server Actions + Route Handlers 承载全部业务写操作；复杂查询用 PostgREST / `supabase-js`。
- **状态管理**：Server State 为主（RSC 直接查询）；仅聊天输入、swipe deck 等局部 UI 状态用 React state，不引入全局 store（遵循"不无意义增加复杂依赖"，暂不需要 Zustand）。

## 2. 关键技术决策

| 决策 | 选择 | 理由 |
|---|---|---|
| 框架 | Next.js 15 App Router + TS strict | 要求指定 |
| UI | Tailwind CSS v4 + shadcn/ui + lucide-react | 要求指定；shadcn 代码进仓库可完全控制 |
| i18n | next-intl（无路由前缀，cookie 存 locale） | 活跃维护；`locales/{zh-CN,en-US}.json`，加语种=加 JSON |
| 表单 | react-hook-form + zod + @hookform/resolvers | 要求指定 |
| 认证 | Supabase Auth（email+password）+ Demo Login | 手机短信需服务商，开发期用邮箱 + 一键 Demo；表单预留手机号 |
| 实时 | Supabase Realtime：`postgres_changes` 订阅 messages 插入；`broadcast` 做 typing/online | 免自建 WebSocket（替代参考项目的 Socket.IO） |
| 图片 | Supabase Storage（头像/照片/Moments/活动封面）+ DiceBear 占位头像 | 不引用真实人物身份 |
| AI | `AIProvider` 接口；`OpenAICompatibleProvider`（env 指向 GLM/OpenAI 等）；`TemplateProvider` 无 Key 降级 | 不绑定单一模型 |
| 测试 | vitest：matching 纯函数 + zod schema + 关键 action 逻辑 | 要求可单测 |
| 本地开发 | supabase CLI + Docker（本项目实例用 5532x 端口，避开机器上已有实例） | 全链路真实运行 |

## 3. 目录结构

```
unibridge/
├─ docs/                      # 产品/架构/DB 文档
├─ locales/                   # zh-CN.json / en-US.json（预留 fr/vi/th/ru/ko/ja）
├─ supabase/
│  ├─ config.toml
│  └─ migrations/             # 0001_init.sql（schema+RLS）…
│  └─ seed.sql                # 30 用户 / 20 Moments / 8 Events / matches / messages
├─ src/
│  ├─ app/
│  │  ├─ (auth)/login|signup  # 未登录可见
│  │  ├─ (main)/              # 登录后：底部/顶部导航布局
│  │  │  ├─ discover/  moments/  events/  messages/  profile/
│  │  ├─ onboarding/          # 7 步问卷
│  │  ├─ admin/               # 角色守卫
│  │  ├─ api/                 # ai/icebreaker, ai/translate, webhooks
│  │  └─ actions 分散到各模块文件夹或 lib/actions
│  ├─ components/             # ui/(shadcn) + 业务组件（swipe-deck, chat, moment-card…）
│  ├─ lib/                    # 见上图
│  ├─ types/                  # 数据库生成类型 + 领域类型
│  └─ middleware.ts           # 会话守卫 / onboarding 完整性 / 封禁拦截
├─ public/manifest.json, icons/
└─ TODO.md README.md
```

## 4. 页面与路由

| 路由 | 渲染 | 说明 |
|---|---|---|
| `/` | RSC | Landing：Logo + Slogan + Get Started |
| `/login` `/signup` | Client | 邮箱密码 + Demo Login 按钮 |
| `/onboarding` | Client(7 步) | 国家→身份→学校→语言→目标→兴趣≥3→照片/Bio |
| `/discover` | RSC+Client | 五 Tab；卡片 X / Say Hi / Connect |
| `/profile/[id]` `/profile` | RSC | 他人/自己主页；认证徽章、Moments、Events |
| `/messages` `/messages/[id]` | RSC+Client | 会话列表；Realtime 聊天 + Icebreaker |
| `/moments` `/moments/new` | RSC+Client | 信息流 + 发布 |
| `/events` `/events/[id]` `/events/new` | RSC+Client | 分类/详情/Join/Create |
| `/admin/*` | RSC | dashboard/users/reports/posts/events/verifications |
| `/settings` | Client | 语言切换、定位开关、Block 列表、登出 |

**Middleware**：无 session → `/login`；有 session 但 `profiles.onboarded=false` → `/onboarding`；`status='banned'` → 403 页；`/admin` 仅 `role='admin'`。

## 5. 匹配与数据流

1. Discover 请求 → `lib/data/discover.ts` 一次性拉取候选（排除：自己、已 like/pass、已 match、blocked、banned）→ `lib/matching/score.ts` 服务端打分排序 → 返回带 `reasons[]` 的卡片数据。
2. Connect → `likeUser(from,to,kind)` Server Action：插入 `likes`；若存在反向 like → 事务内建 `matches` + `conversations` + 双方 `conversation_members` + 双方 `notifications(match)`。
3. 聊天：`messages` 表插入 → Realtime `postgres_changes` 推送双方客户端；`broadcast` 频道发 typing；`conversation_members.last_read_at` 实现 Read 回执。
4. Icebreaker：Route Handler `/api/ai/icebreaker` → `AIProvider.generateIcebreakers(ctx)` → 安全 system prompt + 3 条开场白；失败降级模板。

## 6. 安全设计

- **RLS 全表启用**（见 database-schema.md）：owner 可写自己的行；会话成员可读会话消息；block 用 security-definer 函数 `fn_is_blocked(a,b)` 在各查询中过滤，同时 RLS 层面 messages/conversation_members 检查双向 block。
- **隐私**：profiles 仅存 `city` + 可选 `lat/lng`（模糊到 ~2km）；API 永不返回 email/phone 给他人；定位关闭后不参与距离分。
- **Admin**：`profiles.role='admin'` + RLS `is_admin()` 守卫管理接口；封禁 = `profiles.status='banned'` + middleware 拦截。
- **AI 安全**：system prompt 固化安全约束；输出经基础敏感词过滤兜底。

## 7. 验证策略

- `npm run lint` / `tsc --noEmit` / `npm run build` / `vitest` 每阶段必跑。
- 本地 Supabase 真实数据闭环手测（seed 后 30 用户可见、可 match、可聊天）。
- 响应式断点 375/390/768/1024/1440 检查无横向滚动/溢出。
