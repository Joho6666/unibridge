-- UniBridge Seed Data
-- Creates demo data: schools, languages, interests, 30 users, 20 posts, 8 events, matches, messages

-- ============================================================================
-- BASE DATA
-- ============================================================================

-- Languages (20 common languages)
INSERT INTO languages (code, name_en, name_zh, native_name) VALUES
('zh', 'Chinese', '中文', '中文'),
('en', 'English', '英语', 'English'),
('fr', 'French', '法语', 'Français'),
('de', 'German', '德语', 'Deutsch'),
('es', 'Spanish', '西班牙语', 'Español'),
('ja', 'Japanese', '日语', '日本語'),
('ko', 'Korean', '韩语', '한국어'),
('ru', 'Russian', '俄语', 'Русский'),
('ar', 'Arabic', '阿拉伯语', 'العربية'),
('pt', 'Portuguese', '葡萄牙语', 'Português'),
('it', 'Italian', '意大利语', 'Italiano'),
('vi', 'Vietnamese', '越南语', 'Tiếng Việt'),
('th', 'Thai', '泰语', 'ภาษาไทย'),
('hi', 'Hindi', '印地语', 'हिन्दी'),
('tr', 'Turkish', '土耳其语', 'Türkçe'),
('nl', 'Dutch', '荷兰语', 'Nederlands'),
('pl', 'Polish', '波兰语', 'Polski'),
('sv', 'Swedish', '瑞典语', 'Svenska'),
('id', 'Indonesian', '印尼语', 'Bahasa Indonesia'),
('ms', 'Malay', '马来语', 'Bahasa Melayu');

-- Interests (18 items)
INSERT INTO interests (key, name_en, name_zh, emoji, category) VALUES
('photography', 'Photography', '摄影', '📷', 'creative'),
('travel', 'Travel', '旅行', '✈️', 'lifestyle'),
('ai', 'AI & Tech', 'AI与科技', '🤖', 'tech'),
('movies', 'Movies', '电影', '🎬', 'entertainment'),
('music', 'Music', '音乐', '🎵', 'entertainment'),
('gaming', 'Gaming', '游戏', '🎮', 'entertainment'),
('fitness', 'Fitness', '健身', '💪', 'sports'),
('badminton', 'Badminton', '羽毛球', '🏸', 'sports'),
('basketball', 'Basketball', '篮球', '🏀', 'sports'),
('football', 'Football/Soccer', '足球', '⚽', 'sports'),
('hiking', 'Hiking', '徒步', '🥾', 'outdoor'),
('coffee', 'Coffee', '咖啡', '☕', 'food'),
('chinese_food', 'Chinese Food', '中餐', '🥢', 'food'),
('nightlife', 'Nightlife', '夜生活', '🌃', 'lifestyle'),
('anime', 'Anime', '动漫', '🎌', 'entertainment'),
('books', 'Books', '读书', '📚', 'creative'),
('art', 'Art', '艺术', '🎨', 'creative'),
('cooking', 'Cooking', '烹饪', '👨‍🍳', 'food');

-- Schools (12 Chinese universities)
INSERT INTO schools (name, name_zh, city, country_code) VALUES
('Tsinghua University', '清华大学', 'Beijing', 'CN'),
('Peking University', '北京大学', 'Beijing', 'CN'),
('Fudan University', '复旦大学', 'Shanghai', 'CN'),
('Shanghai Jiao Tong University', '上海交通大学', 'Shanghai', 'CN'),
('Zhejiang University', '浙江大学', 'Hangzhou', 'CN'),
('Nanjing University', '南京大学', 'Nanjing', 'CN'),
('University of Science and Technology of China', '中国科学技术大学', 'Hefei', 'CN'),
('Wuhan University', '武汉大学', 'Wuhan', 'CN'),
('Sun Yat-sen University', '中山大学', 'Guangzhou', 'CN'),
('Renmin University of China', '中国人民大学', 'Beijing', 'CN'),
('Beijing Normal University', '北京师范大学', 'Beijing', 'CN'),
('Tongji University', '同济大学', 'Shanghai', 'CN');

-- ============================================================================
-- USERS (30 demo users + 1 admin, password: demo1234)
-- ============================================================================

-- Helper: Get school IDs
DO $$
DECLARE
  school_tsinghua uuid;
  school_pku uuid;
  school_fudan uuid;
  school_sjtu uuid;
  school_zju uuid;
  user_id uuid;
BEGIN
  SELECT id INTO school_tsinghua FROM schools WHERE name = 'Tsinghua University';
  SELECT id INTO school_pku FROM schools WHERE name = 'Peking University';
  SELECT id INTO school_fudan FROM schools WHERE name = 'Fudan University';
  SELECT id INTO school_sjtu FROM schools WHERE name = 'Shanghai Jiao Tong University';
  SELECT id INTO school_zju FROM schools WHERE name = 'Zhejiang University';

  -- User 1: Emma (France, learning Chinese)
  user_id := gen_random_uuid();
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (user_id, 'emma@demo.com', crypt('demo1234', gen_salt('bf')), now(), now(), now());
  
  INSERT INTO profiles (user_id, display_name, country_code, identity, school_id, major, birth_year, gender, city, bio, tagline, looking_for, onboarded, avatar_url)
  VALUES (user_id, 'Emma', 'FR', 'international_student', school_pku, 'Chinese Language', 2002, 'female', 'Beijing', 
    'French student learning Mandarin. Love photography and city walks!', 'Bonjour from Beijing 🇫🇷',
    ARRAY['language_exchange', 'friends', 'city_exploring'], true,
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Emma');
  INSERT INTO user_languages (user_id, language_code, skill, is_learning) VALUES
    (user_id, 'fr', 'native', false),
    (user_id, 'en', 'c1', false),
    (user_id, 'zh', 'a2', true);
  INSERT INTO user_interests (user_id, interest_key) VALUES
    (user_id, 'photography'), (user_id, 'travel'), (user_id, 'coffee'), (user_id, 'art');

  -- User 2: Li Wei (China, learning English)
  user_id := gen_random_uuid();
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (user_id, 'liwei@demo.com', crypt('demo1234', gen_salt('bf')), now(), now(), now());
  
  INSERT INTO profiles (user_id, display_name, country_code, identity, school_id, major, birth_year, gender, city, bio, tagline, looking_for, onboarded, avatar_url)
  VALUES (user_id, '李伟', 'CN', 'chinese_student', school_tsinghua, 'Computer Science', 2001, 'male', 'Beijing',
    '清华CS学生，想练习英语口语，也可以教你地道中文！', '来自北京的程序员 👨‍💻',
    ARRAY['language_exchange', 'friends', 'tech_networking'], true,
    'https://api.dicebear.com/7.x/avataaars/svg?seed=LiWei');
  INSERT INTO user_languages (user_id, language_code, skill, is_learning) VALUES
    (user_id, 'zh', 'native', false),
    (user_id, 'en', 'b2', true);
  INSERT INTO user_interests (user_id, interest_key) VALUES
    (user_id, 'ai'), (user_id, 'gaming'), (user_id, 'basketball'), (user_id, 'coffee');

  -- PLACEHOLDER_MORE_USERS
END $$;

-- PLACEHOLDER_POSTS

