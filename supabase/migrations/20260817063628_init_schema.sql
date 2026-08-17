-- UniBridge Initial Schema Migration
-- Creates all tables, RLS policies, triggers, and helper functions

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- SIMPLE HELPER FUNCTIONS (no table dependencies)
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_auth_uid()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT auth.uid();
$$;

-- ============================================================================
-- BASE TABLES (public read)
-- ============================================================================

CREATE TABLE schools (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  name_zh text,
  city text NOT NULL,
  country_code text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE languages (
  code text PRIMARY KEY,
  name_en text NOT NULL,
  name_zh text NOT NULL,
  native_name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE interests (
  key text PRIMARY KEY,
  name_en text NOT NULL,
  name_zh text NOT NULL,
  emoji text,
  category text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- USER PROFILE & RELATED
-- ============================================================================

CREATE TABLE profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  display_name text NOT NULL,
  avatar_url text,
  birth_year integer,
  gender text CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  country_code text NOT NULL,
  identity text NOT NULL CHECK (identity IN ('chinese_student', 'international_student', 'exchange_student', 'young_professional')),
  school_id uuid REFERENCES schools,
  major text,
  degree text,
  graduation_year integer,
  bio text,
  tagline text,
  city text,
  lat numeric,
  lng numeric,
  location_visible boolean DEFAULT true,
  photos jsonb DEFAULT '[]'::jsonb,
  looking_for text[] DEFAULT '{}'::text[],
  onboarded boolean DEFAULT false,
  role text DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  status text DEFAULT 'active' CHECK (status IN ('active', 'banned')),
  last_active_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_profiles_country ON profiles(country_code);
CREATE INDEX idx_profiles_city ON profiles(city);
CREATE INDEX idx_profiles_school ON profiles(school_id);
CREATE INDEX idx_profiles_last_active ON profiles(last_active_at DESC);

CREATE TABLE user_languages (
  user_id uuid REFERENCES profiles ON DELETE CASCADE,
  language_code text REFERENCES languages ON DELETE CASCADE,
  skill text NOT NULL CHECK (skill IN ('native', 'c2', 'c1', 'b2', 'b1', 'a2', 'a1', 'beginner')),
  is_learning boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, language_code)
);

CREATE TABLE user_interests (
  user_id uuid REFERENCES profiles ON DELETE CASCADE,
  interest_key text REFERENCES interests ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, interest_key)
);

-- ============================================================================
-- MATCHING & CONNECTIONS
-- ============================================================================

CREATE TABLE likes (
  from_user uuid REFERENCES profiles ON DELETE CASCADE,
  to_user uuid REFERENCES profiles ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('like', 'super_like', 'pass')),
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (from_user, to_user),
  CHECK (from_user <> to_user)
);

CREATE INDEX idx_likes_to_user ON likes(to_user);

CREATE TABLE matches (
  user_a uuid REFERENCES profiles ON DELETE CASCADE,
  user_b uuid REFERENCES profiles ON DELETE CASCADE,
  conversation_id uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_a, user_b),
  CHECK (user_a < user_b)
);

-- ============================================================================
-- CHAT
-- ============================================================================

CREATE TABLE conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid,
  last_message_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC);

CREATE TABLE conversation_members (
  conversation_id uuid REFERENCES conversations ON DELETE CASCADE,
  user_id uuid REFERENCES profiles ON DELETE CASCADE,
  last_read_at timestamptz DEFAULT now(),
  joined_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX idx_conversation_members_user ON conversation_members(user_id);

CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES conversations ON DELETE CASCADE NOT NULL,
  sender_id uuid REFERENCES profiles ON DELETE CASCADE NOT NULL,
  content text,
  type text DEFAULT 'text' CHECK (type IN ('text', 'image')),
  image_url text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);

-- ============================================================================
-- MOMENTS (Social Feed)
-- ============================================================================

CREATE TABLE posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id uuid REFERENCES profiles ON DELETE CASCADE NOT NULL,
  content text NOT NULL,
  tags text[] DEFAULT '{}'::text[],
  hidden boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);

CREATE TABLE post_images (
  post_id uuid REFERENCES posts ON DELETE CASCADE,
  url text NOT NULL,
  sort integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (post_id, sort)
);

CREATE TABLE post_likes (
  post_id uuid REFERENCES posts ON DELETE CASCADE,
  user_id uuid REFERENCES profiles ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES posts ON DELETE CASCADE NOT NULL,
  author_id uuid REFERENCES profiles ON DELETE CASCADE NOT NULL,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_comments_post ON comments(post_id, created_at DESC);

CREATE TABLE follows (
  follower_id uuid REFERENCES profiles ON DELETE CASCADE,
  followee_id uuid REFERENCES profiles ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (follower_id, followee_id),
  CHECK (follower_id <> followee_id)
);

-- ============================================================================
-- EVENTS
-- ============================================================================

CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id uuid REFERENCES profiles ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  cover_url text,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  city text NOT NULL,
  location_name text,
  lat numeric,
  lng numeric,
  max_participants integer,
  languages text[] DEFAULT '{}'::text[],
  category text NOT NULL,
  price numeric DEFAULT 0,
  requirements text,
  status text DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'deleted')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_events_starts_at ON events(starts_at);
CREATE INDEX idx_events_city ON events(city);
CREATE INDEX idx_events_category ON events(category);

CREATE TABLE event_members (
  event_id uuid REFERENCES events ON DELETE CASCADE,
  user_id uuid REFERENCES profiles ON DELETE CASCADE,
  joined_at timestamptz DEFAULT now(),
  PRIMARY KEY (event_id, user_id)
);

-- ============================================================================
-- SAFETY & MODERATION
-- ============================================================================

CREATE TABLE reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES profiles ON DELETE CASCADE NOT NULL,
  target_user uuid REFERENCES profiles ON DELETE SET NULL,
  target_type text NOT NULL CHECK (target_type IN ('user', 'post', 'event', 'message')),
  target_id uuid,
  category text NOT NULL CHECK (category IN ('harassment', 'spam', 'scam', 'sexual_content', 'fake_profile', 'discrimination', 'other')),
  reason text,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'resolved', 'dismissed')),
  handled_by uuid REFERENCES profiles ON DELETE SET NULL,
  handled_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_reports_status ON reports(status, created_at DESC);

CREATE TABLE blocks (
  blocker_id uuid REFERENCES profiles ON DELETE CASCADE,
  blocked_id uuid REFERENCES profiles ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

CREATE TABLE verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles ON DELETE CASCADE NOT NULL,
  type text NOT NULL CHECK (type IN ('university', 'identity')),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  submitted_note text,
  reviewed_by uuid REFERENCES profiles ON DELETE SET NULL,
  reviewed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_verifications_user ON verifications(user_id);

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles ON DELETE CASCADE NOT NULL,
  type text NOT NULL CHECK (type IN ('match', 'like', 'message', 'comment', 'event', 'comment_mention', 'system')),
  title text NOT NULL,
  body text NOT NULL,
  data jsonb DEFAULT '{}'::jsonb,
  read boolean DEFAULT false,
  link text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, read, created_at DESC);

-- ============================================================================
-- HELPER FUNCTIONS (depend on tables, must be created after tables)
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COALESCE(
    (SELECT role = 'admin' FROM profiles WHERE user_id = auth.uid()),
    false
  );
$$;

CREATE OR REPLACE FUNCTION fn_is_blocked(user_a uuid, user_b uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS(
    SELECT 1 FROM blocks 
    WHERE (blocker_id = user_a AND blocked_id = user_b)
       OR (blocker_id = user_b AND blocked_id = user_a)
  );
$$;

CREATE OR REPLACE FUNCTION fn_are_matched(user_a uuid, user_b uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS(
    SELECT 1 FROM matches
    WHERE (matches.user_a = LEAST(user_a, user_b) 
       AND matches.user_b = GREATEST(user_a, user_b))
  );
$$;

CREATE OR REPLACE FUNCTION fn_share_conversation(uid uuid, conv_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS(
    SELECT 1 FROM conversation_members
    WHERE conversation_id = conv_id AND user_id = uid
  );
$$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Base tables: public read
CREATE POLICY "schools_select" ON schools FOR SELECT USING (true);
CREATE POLICY "languages_select" ON languages FOR SELECT USING (true);
CREATE POLICY "interests_select" ON interests FOR SELECT USING (true);

-- Profiles
CREATE POLICY "profiles_select" ON profiles FOR SELECT
USING (
  status = 'active'
  AND NOT fn_is_blocked(user_id, fn_auth_uid())
  OR user_id = fn_auth_uid()
  OR fn_is_admin()
);

CREATE POLICY "profiles_insert" ON profiles FOR INSERT
WITH CHECK (user_id = fn_auth_uid());

CREATE POLICY "profiles_update" ON profiles FOR UPDATE
USING (user_id = fn_auth_uid())
WITH CHECK (user_id = fn_auth_uid());

-- User languages/interests: own for write, public for read
CREATE POLICY "user_languages_select" ON user_languages FOR SELECT USING (true);
CREATE POLICY "user_languages_insert" ON user_languages FOR INSERT WITH CHECK (user_id = fn_auth_uid());
CREATE POLICY "user_languages_update" ON user_languages FOR UPDATE USING (user_id = fn_auth_uid());
CREATE POLICY "user_languages_delete" ON user_languages FOR DELETE USING (user_id = fn_auth_uid());

CREATE POLICY "user_interests_select" ON user_interests FOR SELECT USING (true);
CREATE POLICY "user_interests_insert" ON user_interests FOR INSERT WITH CHECK (user_id = fn_auth_uid());
CREATE POLICY "user_interests_delete" ON user_interests FOR DELETE USING (user_id = fn_auth_uid());

-- Likes
CREATE POLICY "likes_select" ON likes FOR SELECT
USING (from_user = fn_auth_uid() OR to_user = fn_auth_uid());

CREATE POLICY "likes_insert" ON likes FOR INSERT
WITH CHECK (from_user = fn_auth_uid() AND NOT fn_is_blocked(from_user, to_user));

CREATE POLICY "likes_delete" ON likes FOR DELETE
USING (from_user = fn_auth_uid());

-- Matches
CREATE POLICY "matches_select" ON matches FOR SELECT
USING (user_a = fn_auth_uid() OR user_b = fn_auth_uid());

-- Conversations & Messages
CREATE POLICY "conversations_select" ON conversations FOR SELECT
USING (fn_share_conversation(fn_auth_uid(), id));

CREATE POLICY "conversation_members_select" ON conversation_members FOR SELECT
USING (fn_share_conversation(fn_auth_uid(), conversation_id) OR user_id = fn_auth_uid());

CREATE POLICY "conversation_members_update" ON conversation_members FOR UPDATE
USING (user_id = fn_auth_uid())
WITH CHECK (user_id = fn_auth_uid());

CREATE POLICY "messages_select" ON messages FOR SELECT
USING (
  fn_share_conversation(fn_auth_uid(), conversation_id)
  AND NOT EXISTS(
    SELECT 1 FROM conversation_members cm1, conversation_members cm2
    WHERE cm1.conversation_id = messages.conversation_id
      AND cm2.conversation_id = messages.conversation_id
      AND cm1.user_id = fn_auth_uid()
      AND cm2.user_id <> fn_auth_uid()
      AND fn_is_blocked(cm1.user_id, cm2.user_id)
  )
);

CREATE POLICY "messages_insert" ON messages FOR INSERT
WITH CHECK (
  sender_id = fn_auth_uid()
  AND fn_share_conversation(fn_auth_uid(), conversation_id)
  AND NOT EXISTS(
    SELECT 1 FROM conversation_members cm1, conversation_members cm2
    WHERE cm1.conversation_id = messages.conversation_id
      AND cm2.conversation_id = messages.conversation_id
      AND cm1.user_id = fn_auth_uid()
      AND cm2.user_id <> fn_auth_uid()
      AND fn_is_blocked(cm1.user_id, cm2.user_id)
  )
);

-- Posts
CREATE POLICY "posts_select" ON posts FOR SELECT
USING (
  (NOT hidden OR author_id = fn_auth_uid() OR fn_is_admin())
  AND NOT fn_is_blocked(author_id, fn_auth_uid())
);

CREATE POLICY "posts_insert" ON posts FOR INSERT
WITH CHECK (author_id = fn_auth_uid());

CREATE POLICY "posts_update" ON posts FOR UPDATE
USING (author_id = fn_auth_uid() OR fn_is_admin())
WITH CHECK (author_id = fn_auth_uid() OR fn_is_admin());

CREATE POLICY "posts_delete" ON posts FOR DELETE
USING (author_id = fn_auth_uid() OR fn_is_admin());

CREATE POLICY "post_images_select" ON post_images FOR SELECT USING (true);
CREATE POLICY "post_images_insert" ON post_images FOR INSERT
WITH CHECK (EXISTS(SELECT 1 FROM posts WHERE id = post_id AND author_id = fn_auth_uid()));
CREATE POLICY "post_images_delete" ON post_images FOR DELETE
USING (EXISTS(SELECT 1 FROM posts WHERE id = post_id AND author_id = fn_auth_uid()));

CREATE POLICY "post_likes_select" ON post_likes FOR SELECT USING (true);
CREATE POLICY "post_likes_insert" ON post_likes FOR INSERT WITH CHECK (user_id = fn_auth_uid());
CREATE POLICY "post_likes_delete" ON post_likes FOR DELETE USING (user_id = fn_auth_uid());

CREATE POLICY "comments_select" ON comments FOR SELECT USING (true);
CREATE POLICY "comments_insert" ON comments FOR INSERT WITH CHECK (author_id = fn_auth_uid());
CREATE POLICY "comments_update" ON comments FOR UPDATE USING (author_id = fn_auth_uid());
CREATE POLICY "comments_delete" ON comments FOR DELETE USING (author_id = fn_auth_uid() OR fn_is_admin());

CREATE POLICY "follows_select" ON follows FOR SELECT USING (true);
CREATE POLICY "follows_insert" ON follows FOR INSERT WITH CHECK (follower_id = fn_auth_uid());
CREATE POLICY "follows_delete" ON follows FOR DELETE USING (follower_id = fn_auth_uid());

-- Events
CREATE POLICY "events_select" ON events FOR SELECT
USING (status = 'active' OR host_id = fn_auth_uid() OR fn_is_admin());

CREATE POLICY "events_insert" ON events FOR INSERT
WITH CHECK (host_id = fn_auth_uid());

CREATE POLICY "events_update" ON events FOR UPDATE
USING (host_id = fn_auth_uid() OR fn_is_admin())
WITH CHECK (host_id = fn_auth_uid() OR fn_is_admin());

CREATE POLICY "events_delete" ON events FOR DELETE
USING (host_id = fn_auth_uid() OR fn_is_admin());

CREATE POLICY "event_members_select" ON event_members FOR SELECT USING (true);
CREATE POLICY "event_members_insert" ON event_members FOR INSERT WITH CHECK (user_id = fn_auth_uid());
CREATE POLICY "event_members_delete" ON event_members FOR DELETE USING (user_id = fn_auth_uid());

-- Reports
CREATE POLICY "reports_select" ON reports FOR SELECT
USING (reporter_id = fn_auth_uid() OR fn_is_admin());

CREATE POLICY "reports_insert" ON reports FOR INSERT
WITH CHECK (reporter_id = fn_auth_uid());

CREATE POLICY "reports_update" ON reports FOR UPDATE
USING (fn_is_admin())
WITH CHECK (fn_is_admin());

-- Blocks
CREATE POLICY "blocks_select" ON blocks FOR SELECT
USING (blocker_id = fn_auth_uid());

CREATE POLICY "blocks_insert" ON blocks FOR INSERT
WITH CHECK (blocker_id = fn_auth_uid());

CREATE POLICY "blocks_delete" ON blocks FOR DELETE
USING (blocker_id = fn_auth_uid());

-- Verifications
CREATE POLICY "verifications_select" ON verifications FOR SELECT
USING (user_id = fn_auth_uid() OR fn_is_admin());

CREATE POLICY "verifications_insert" ON verifications FOR INSERT
WITH CHECK (user_id = fn_auth_uid());

CREATE POLICY "verifications_update" ON verifications FOR UPDATE
USING (fn_is_admin())
WITH CHECK (fn_is_admin());

-- Notifications
CREATE POLICY "notifications_select" ON notifications FOR SELECT
USING (user_id = fn_auth_uid());

CREATE POLICY "notifications_insert" ON notifications FOR INSERT
WITH CHECK (user_id = fn_auth_uid());

CREATE POLICY "notifications_update" ON notifications FOR UPDATE
USING (user_id = fn_auth_uid())
WITH CHECK (user_id = fn_auth_uid());

CREATE POLICY "notifications_delete" ON notifications FOR DELETE
USING (user_id = fn_auth_uid());

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at BEFORE UPDATE ON schools FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON languages FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON interests FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON user_languages FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON matches FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON conversation_members FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON reports FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON verifications FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- Protect profiles role/status from non-admin updates
CREATE OR REPLACE FUNCTION trigger_protect_profiles_role()
RETURNS TRIGGER AS $$
BEGIN
  -- Only admins can change role and status
  IF OLD.role IS DISTINCT FROM NEW.role OR OLD.status IS DISTINCT FROM NEW.status THEN
    IF NOT EXISTS(SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin') THEN
      NEW.role = OLD.role;
      NEW.status = OLD.status;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER protect_profiles_role BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION trigger_protect_profiles_role();

-- Update conversation last_message_at when message inserted
CREATE OR REPLACE FUNCTION trigger_update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations 
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conversation_timestamp AFTER INSERT ON messages
FOR EACH ROW EXECUTE FUNCTION trigger_update_conversation_timestamp();

-- Add foreign key for matches.conversation_id (deferred to allow circular reference)
ALTER TABLE matches ADD CONSTRAINT fk_matches_conversation 
FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE SET NULL;

