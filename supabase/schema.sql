-- ================================================================
-- BS16 Hub — Complete Supabase Schema
-- Run this in your Supabase SQL editor (Dashboard → SQL Editor)
-- ================================================================

-- ── Profiles ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name  TEXT,
  phone_number  TEXT,
  postcode      TEXT,
  neighbourhood TEXT CHECK (neighbourhood IN ('Lyde Green', 'Emersons Green')),
  role          TEXT DEFAULT 'homeowner' CHECK (role IN ('homeowner', 'trader', 'admin')),
  bs16_verified BOOLEAN DEFAULT FALSE,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Trader profiles ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.trader_profiles (
  id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id              UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
  business_name        TEXT NOT NULL,
  phone_number         TEXT NOT NULL,
  bio                  TEXT,
  trades               TEXT[] NOT NULL DEFAULT '{}',
  gas_safe_number      TEXT,
  google_reviews_url   TEXT,
  checkatrade_url      TEXT,
  is_approved          BOOLEAN DEFAULT FALSE,
  approved_at          TIMESTAMPTZ,
  approved_by          UUID,
  rejected_at          TIMESTAMPTZ,
  reject_reason        TEXT,
  created_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ── Jobs ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.jobs (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title         TEXT NOT NULL,
  description   TEXT NOT NULL,
  category      TEXT NOT NULL CHECK (category IN ('Home Maintenance', 'Gardening & Outdoors')),
  photo_url     TEXT,
  neighbourhood TEXT CHECK (neighbourhood IN ('Lyde Green', 'Emersons Green')),
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Market listings ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.market_listings (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title         TEXT NOT NULL,
  description   TEXT,
  price_pence   INTEGER,
  is_free_swap  BOOLEAN DEFAULT FALSE,
  status        TEXT DEFAULT 'available' CHECK (status IN ('available', 'gone')),
  image_url     TEXT,
  neighbourhood TEXT NOT NULL,
  is_visible    BOOLEAN DEFAULT TRUE,
  flag_count    INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Notice posts ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notice_posts (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
  tag           TEXT NOT NULL CHECK (tag IN ('Event', 'Lost & Found', 'Local News')),
  neighbourhood TEXT NOT NULL,
  is_visible    BOOLEAN DEFAULT TRUE,
  flag_count    INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Watch alerts ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.watch_alerts (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
  urgency       TEXT NOT NULL DEFAULT 'general' CHECK (urgency IN ('urgent', 'general')),
  neighbourhood TEXT NOT NULL,
  is_visible    BOOLEAN DEFAULT TRUE,
  flag_count    INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Content flags ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.content_flags (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  target_table TEXT NOT NULL,
  target_id    UUID NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(reporter_id, target_table, target_id)
);

-- ── Chat rooms ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.chat_rooms (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id     UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
  listing_id UUID REFERENCES public.market_listings(id) ON DELETE CASCADE,
  trader_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  homeowner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(job_id, trader_id)
);

-- ── Chat messages ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id    UUID REFERENCES public.chat_rooms(id) ON DELETE CASCADE NOT NULL,
  sender_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Trades pre-registration ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.trades_preregister (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name          TEXT NOT NULL,
  trade_type    TEXT NOT NULL,
  phone         TEXT,
  email         TEXT,
  neighbourhood TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- ROW LEVEL SECURITY
-- ================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trader_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notice_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watch_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Profiles readable by all" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Profiles editable by owner" ON public.profiles FOR ALL USING (auth.uid() = id);

-- Trader profiles
CREATE POLICY "Trader profiles readable by all" ON public.trader_profiles FOR SELECT USING (true);
CREATE POLICY "Trader profiles editable by owner" ON public.trader_profiles FOR ALL USING (auth.uid() = user_id);

-- Jobs
CREATE POLICY "Jobs readable" ON public.jobs FOR SELECT USING (is_active = true);
CREATE POLICY "Jobs own" ON public.jobs FOR ALL USING (auth.uid() = user_id);

-- Market
CREATE POLICY "Market readable" ON public.market_listings FOR SELECT USING (is_visible = true);
CREATE POLICY "Market own" ON public.market_listings FOR ALL USING (auth.uid() = user_id);

-- Notices
CREATE POLICY "Notices readable" ON public.notice_posts FOR SELECT USING (is_visible = true);
CREATE POLICY "Notices own" ON public.notice_posts FOR ALL USING (auth.uid() = user_id);

-- Watch
CREATE POLICY "Watch readable" ON public.watch_alerts FOR SELECT USING (is_visible = true);
CREATE POLICY "Watch own" ON public.watch_alerts FOR ALL USING (auth.uid() = user_id);

-- Flags
CREATE POLICY "Flags insert" ON public.content_flags FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Flags own" ON public.content_flags FOR SELECT USING (auth.uid() = reporter_id);

-- Chat rooms
CREATE POLICY "Chat rooms participants" ON public.chat_rooms FOR SELECT
  USING (auth.uid() = trader_id OR auth.uid() = homeowner_id);
CREATE POLICY "Chat rooms create" ON public.chat_rooms FOR INSERT
  WITH CHECK (auth.uid() = trader_id OR auth.uid() = homeowner_id);

-- Chat messages
CREATE POLICY "Chat messages participants" ON public.chat_messages FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.chat_rooms r
    WHERE r.id = room_id
    AND (r.trader_id = auth.uid() OR r.homeowner_id = auth.uid())
  ));
CREATE POLICY "Chat messages send" ON public.chat_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- ================================================================
-- AUTO-HIDE at 3 flags
-- ================================================================
CREATE OR REPLACE FUNCTION public.increment_flag_count(p_table TEXT, p_id UUID)
RETURNS VOID AS $$
BEGIN
  IF p_table = 'market_listings' THEN
    UPDATE public.market_listings
      SET flag_count = flag_count + 1,
          is_visible = CASE WHEN flag_count + 1 >= 3 THEN FALSE ELSE is_visible END
      WHERE id = p_id;
  ELSIF p_table = 'notice_posts' THEN
    UPDATE public.notice_posts
      SET flag_count = flag_count + 1,
          is_visible = CASE WHEN flag_count + 1 >= 3 THEN FALSE ELSE is_visible END
      WHERE id = p_id;
  ELSIF p_table = 'watch_alerts' THEN
    UPDATE public.watch_alerts
      SET flag_count = flag_count + 1,
          is_visible = CASE WHEN flag_count + 1 >= 3 THEN FALSE ELSE is_visible END
      WHERE id = p_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================================
-- AUTO-CREATE PROFILE on signup
-- ================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'homeowner')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ================================================================
-- REALTIME
-- ================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.jobs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.market_listings;
