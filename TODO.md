# UniBridge 开发 TODO

> 规则：每完成一项打勾；每完成一个 Phase 运行 lint / typecheck / build / test 并真实验证。

## Phase 1 — Foundation
- [x] create-next-app 脚手架（TS + Tailwind + ESLint + App Router + src dir）
- [x] docs/（product-research / reference-analysis / architecture / database-schema）
- [ ] 依赖安装（supabase-js/@supabase/ssr, next-intl, zod, rhf, lucide, vitest）
- [ ] shadcn/ui 初始化 + 常用组件
- [ ] locales/zh-CN.json + en-US.json + next-intl 接入（cookie locale，右上角切换）
- [ ] 全局布局：移动底部导航 5 Tab + 桌面顶部导航（max-w-1280）
- [ ] PWA：manifest + icons + theme
- [ ] supabase CLI init + 本地实例（55321 端口组）+ env 模板

## Phase 2 — Auth + Onboarding
- [ ] lib/supabase client/server/admin 三件套
- [ ] /login /signup（邮箱密码）+ Demo Login
- [ ] middleware：会话守卫 / onboarding 检查 / banned 拦截
- [ ] Onboarding 7 步（国家/身份/学校/语言/目标/兴趣≥3/照片+Bio）→ profiles + user_languages + user_interests
- [ ] DB migration 0001（全部表 + RLS + 触发器）+ seed.sql 应用

## Phase 3 — Discover + Profile
- [ ] lib/matching/*：6 个独立打分函数 + 总分 + reasons（vitest）
- [ ] /discover 五 Tab（For You/Nearby/New Here/Same Campus/Language Partners）
- [ ] 用户卡片（头像/名字/年龄/国旗/身份/学校/语言/兴趣/looking for/推荐理由）
- [ ] /profile/[id] + /profile + 编辑入口

## Phase 4 — Match
- [ ] likeUser action（connect/super_hi/pass）+ 双向检测 → match + conversation + notifications
- [ ] It's a Match 弹窗（Send Message / Keep Exploring）
- [ ] 已互动用户不再出现在 Discover

## Phase 5 — Realtime Chat
- [ ] /messages 会话列表（未读数、最后消息）
- [ ] /messages/[id]：text/emoji/image、Realtime postgres_changes、typing broadcast、online、read 回执
- [ ] 图片上传 Supabase Storage

## Phase 6 — Moments
- [ ] /moments 信息流（图文 1~9 图、标签、点赞/评论/收藏）
- [ ] /moments/new 发布页
- [ ] Follow（follows 表）

## Phase 7 — Events
- [ ] /events 列表 + 分类 Tab + Event Card（封面/时间/人数/国旗墙/价格）
- [ ] /events/[id] 详情（Host/描述/地点/参与者/语言/价格/要求）+ Join
- [ ] /events/new 创建（Title~Price 全字段）

## Phase 8 — Admin
- [ ] /admin 守卫（role=admin）+ Dashboard 指标卡
- [ ] 举报队列（处理/驳回）+ 封禁用户 + 隐藏动态 + 删除活动 + 认证审核
- [ ] verifications 模拟审核流

## Phase 9 — AI
- [ ] AIProvider 接口 + OpenAICompatibleProvider + TemplateProvider 降级
- [ ] /api/ai/icebreaker：按双方国家/语言/学校/兴趣/Bio 生成 3 条开场白（安全 prompt）
- [ ] /api/ai/translate-polish：中↔英 润色/翻译
- [ ] 聊天页 ✨ 按钮 + 翻译 UX

## Phase 10 — Testing + Polish
- [ ] vitest：matching 全套 + zod + 关键 action
- [ ] Block/Report 全链路验证（双向不可见/不可聊）
- [ ] 响应式 375/390/768/1024/1440 无横滚/溢出
- [ ] README（截图/架构/目录/env/migration/seed/运行/部署）
- [ ] 全量 lint + build + 手动验收清单跑通
