# UniBridge（桥友）产品研究

**Slogan**：Meet locals. Meet the world.

## 1. 问题定义

**"外国年轻人在中国很难真正认识中国年轻人；中国年轻人也缺少自然认识外国朋友的渠道。"**

现有产品各自解决了一部分，但没有任何一个产品完整解决这个场景：

| 产品 | 解决了 | 没解决 |
|---|---|---|
| HelloTalk / Tandem | 语言交换匹配、语伴聊天 | 强"学习工具"属性，认识的人关系停留在"语伴"，弱社交沉淀（活动/朋友圈） |
| Tinder / Bumble | 人物匹配、双向确认的社交礼仪 | 陌生人 Dating 心智，外国用户在华渗透率低，且非交友主场景 |
| Bumble BFF | 朋友模式 | 无语言/跨文化维度，在华无网络效应 |
| Meetup / InterNations | 线下活动、国际社区 | 1对1破冰弱，以活动为中心而非以人为中心，中国年轻人少 |
| 小红书 | 信息流、生活方式种草 | 无匹配、无关系链，评论式弱社交 |

**UniBridge 的定位 = 人物匹配（双向 Like → Match）× 语言互补 × 校园社区 × 活动 × 信息流**，即把上述五类产品的核心闭环组合到一个以"跨文化 friendships first"为心智的平台。

## 2. 目标用户

1. **中国大学生**：想练口语、想认识外国朋友、对世界好奇。
2. **在中国的国际学生 / 交换生 / 年轻职场人**：想学中文、融入本地生活、缺本地社交圈。

## 3. 核心闭环（MVP 必须真实可用）

```
注册 → Onboarding 7 步资料 → Discover 浏览推荐 → Connect/Say Hi/Skip
→ 双向 Like 形成 Match → Realtime Chat（AI Icebreaker / 润色 / 翻译）
→ 发 Moments / 点赞评论 → 浏览 Events → Join Event → 创建 Event
→ 查看Profile → Block / Report → Admin 处理举报
```

## 4. 功能优先级

| 模块 | 优先级 | 说明 |
|---|---|---|
| Auth + Onboarding | P0 | 邮箱注册 + Demo Login；7 步问卷 |
| Discover + Matching | P0 | 可解释打分制推荐；For You/Nearby/New/Same Campus/Language Partners 五个 Tab |
| Like / Match | P0 | 单向 like 记录、双向即 match、自动建 conversation |
| Chat | P0 | Supabase Realtime；text/emoji/image；online/typing/read |
| Moments | P1 | 图文动态 + 标签 + like/comment/save/follow |
| Events | P1 | 列表/分类/详情/Join/Create；价格仅信息字段 |
| 安全（Block/Report） | P0 | 最高优先级模块；被 block 双向隔离 |
| Admin | P1 | 数据看板 + 举报处理 + 封禁 + 隐藏动态/删活动 + 认证审核 |
| AI | P1 | Icebreaker 3 条开场白 + 中英互译润色；AIProvider 抽象 |
| PWA / i18n | P1 | manifest + 中英双语，预留 6 语种 |

## 5. 匹配算法（可解释，无黑盒）

总分 100：

- **Language Complementarity 30**：我学的语言=对方母语（且对方学我的母语）得分最高；等级互补加权。
- **Shared Interests 20**：共同兴趣数（cap 到上限）。
- **Looking For Compatibility 20**：双方 looking-for 交集。
- **Distance 15**：城市内距离分（只存模糊坐标，展示"约 x km"）。
- **Same School / Similar Age 10**：同校满分，年龄差衰减。
- **Activity Score 5**：对方最近活跃度。

每项独立函数于 `lib/matching/`，vitest 单测；未来可整体替换为 AI Ranking 而不动调用方。

## 6. 安全与隐私红线

- 手机号/邮箱/精确坐标/证件号永不公开；定位只显示"约 N km"，且可关闭。
- 不存储真实身份证/护照图片；认证第一版为模拟状态。
- Block 后：双向不可见资料、不可聊天、不可匹配（查询层 + RLS 双重过滤）。
- 举报 7 分类：Harassment / Spam / Scam / Sexual Content / Fake Profile / Discrimination / Other。
- AI 生成内容注入安全 system prompt，禁止色情/骚扰/歧视/攻击/政治煽动。

## 7. 视觉方向

Young · International · Campus · Warm · Clean · Premium · Friendly。大量留白、大圆角卡片、轻微阴影、国旗 Emoji、兴趣标签、自然渐变；移动优先 + 底部五 Tab（Discover / Moments / Events / Messages / Me）；Desktop 最大宽度 1280px + 顶部导航。参考 Airbnb/Bumble/Instagram 的气质但不复制品牌资产。
