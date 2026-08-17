# UniBridge 数据库设计（Supabase PostgreSQL）

所有表含 `created_at timestamptz default now()`、`updated_at timestamptz default now()`（触发器自动更新）。主键 `uuid default gen_random_uuid()`（关联 auth.users 的表用 `uuid references auth.users`）。

## ER 概览

```
auth.users ──1:1── profiles ──┬─< user_languages >── languages
                              ├─< user_interests >── interests
                              ├─< likes >──────────────┐
                              ├─< matches >            │ 双向
                              ├─< conversation_members >── conversations ──< messages
                              ├─< posts ──< post_images / post_likes / comments
                              ├─< event_members >── events
                              ├─< reports / blocks / verifications / notifications
schools ── profiles.school_id
```

## 表清单（23 张）

### 基础维表
| 表 | 关键字段 | 约束/索引 |
|---|---|---|
| schools | name, name_zh, city, country_code | unique(name) |
| languages | code(unique), name_en, name_zh, native_name | seed ~20 语言 |
| interests | key(unique), name_en, name_zh, emoji, category | seed 18 项 |

### 用户
| 表 | 关键字段 | 说明 |
|---|---|---|
| profiles | user_id PK→auth.users, display_name, avatar_url, birth_year, gender, country_code, identity(chinese_student/international_student/exchange_student/young_professional), school_id→schools, major, degree, graduation_year, bio, tagline(一句话), city, lat, lng, location_visible bool, photos jsonb(url数组≤6), looking_for text[] , onboarded bool, role(user/admin), status(active/banned), last_active_at | unique(user_id); idx(country_code),(city),(school_id),(last_active_at) |
| user_languages | user_id, language_code, skill(native/c2/c1/b2/b1/a2/a1/beginner), is_learning bool | PK(user_id,language_code) |
| user_interests | user_id, interest_key | PK(user_id,interest_key) |

### 匹配
| 表 | 关键字段 | 说明 |
|---|---|---|
| likes | from_user, to_user, kind(like/super_like/pass), created_at | PK(from_user,to_user)；idx(to_user) 查反向；CHECK from<>to |
| matches | user_a, user_b (a<b 字典序), conversation_id→conversations | unique(user_a,user_b)；match 时建 conversation |

### 会话与消息
| 表 | 关键字段 | 说明 |
|---|---|---|
| conversations | id, match_id→matches, last_message_at | idx(last_message_at) |
| conversation_members | conversation_id, user_id, last_read_at, joined_at | PK(conversation_id,user_id)；idx(user_id) |
| messages | conversation_id, sender_id, content text, type(text/image), image_url, created_at | idx(conversation_id,created_at) |

### Moments
| 表 | 关键字段 | 说明 |
|---|---|---|
| posts | author_id, content, tags text[], hidden bool default false | idx(author_id),(created_at desc) |
| post_images | post_id, url, sort | PK(post_id,sort) 1~9 图 |
| post_likes | post_id, user_id | PK(post_id,user_id) |
| comments | post_id, author_id, content | idx(post_id) |
| follows | follower_id, followee_id | PK(follower_id,followee_id)，Moments 的 Follow |

### 活动
| 表 | 关键字段 | 说明 |
|---|---|---|
| events | host_id, title, description, cover_url, starts_at timestamptz, end_at, city, location_name, lat, lng, max_participants int, languages text[], category(today/this_week/language_exchange/food/sports/city_walk/party/study/culture), price numeric, requirements text, status(active/cancelled/deleted) | idx(starts_at),(city),(category) |
| event_members | event_id, user_id, joined_at | PK(event_id,user_id)；Join 即插入 |

### 安全与运营
| 表 | 关键字段 | 说明 |
|---|---|---|
| reports | reporter_id, target_user, target_type(user/post/event/message), target_id uuid, category(harassment/spam/scam/sexual_content/fake_profile/discrimination/other), reason text, status(pending/resolved/dismissed), handled_by, handled_at | idx(status) |
| blocks | blocker_id, blocked_id | PK(blocker_id,blocked_id)；双向过滤 |
| verifications | user_id, type(university/identity), status(pending/approved/rejected), submitted_note, reviewed_by, reviewed_at | idx(user_id) |
| notifications | user_id, type(match/like/message/comment/event/comment_mention/system), title, body, data jsonb, read bool, link | idx(user_id,read,created_at desc) |

## RLS 策略（全部启用，不关闭）

公共辅助函数（security definer，避免递归）：
```sql
fn_auth_uid()            -- auth.uid()
fn_is_admin()            -- profiles.role='admin'
fn_is_blocked(a,b)       -- 存在任一方向 block
fn_are_matched(a,b)      -- 存在 match
fn_share_conversation(u,c)
```

| 表 | 策略要点 |
|---|---|
| schools/languages/interests | public SELECT |
| profiles | SELECT: 非 banned 且未被我 block/block 我（admin 全量）；INSERT/UPDATE: 仅本人（role/status 等敏感列用 trigger 保护，仅 admin 可改） |
| user_languages/user_interests | 本人读写；public SELECT（展示需要） |
| likes | SELECT: 涉及自己的行；INSERT/DELETE: 仅 from=自己 |
| matches | SELECT: user_a/user_b 之一是自己 |
| conversations | SELECT: 是成员 |
| conversation_members | SELECT: 是会话成员或本人行；UPDATE last_read_at 仅本人 |
| messages | SELECT: 所在会话成员且双方未 block；INSERT: 会话成员且 sender=自己且未双向 block |
| posts | SELECT: 未 hidden（作者本人/admin 可见 hidden）；INSERT/UPDATE/DELETE: 作者（hidden 仅 admin） |
| post_likes/comments | SELECT public；INSERT/DELETE 本人 |
| events | SELECT: status=active（host/admin 全量）；INSERT/UPDATE/DELETE: host（status 仅 admin） |
| event_members | SELECT public（显示参与者）；INSERT: 本人且活动未满员未开始（满员校验同时走 action 层事务） |
| reports | INSERT 本人；SELECT: 本人或 admin；UPDATE 仅 admin |
| blocks | 本人全权；他人不可见 |
| verifications | 本人 INSERT/SELECT；UPDATE 仅 admin |
| notifications | 本人读写 |

## 触发器

1. `set_updated_at`：所有表 UPDATE 前刷新 updated_at。
2. `profiles_protect_role`：非 admin 更新 profiles 时忽略 role/status 变更。
3. `messages_update_conversation`：插入 message 时更新 conversations.last_message_at。

## Seed 概要

- ~20 语言、18 兴趣、10+ 中国高校。
- 30 用户（12 国籍，真实风格姓名，DiceBear 头像，完整语言/兴趣/looking_for），1 个 admin。
- 20 条 Moments（含图与标签）、若干 like/comment。
- 8 个 Events（火锅局/语言角/City Walk/羽毛球/观影…）。
- 10 组 matches（含 conversation 与 30 条 messages）。
- Demo Login 账号密码统一 `demo1234`。
