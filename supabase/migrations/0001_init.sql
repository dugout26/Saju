-- ============================================================
-- Unse — Initial schema (Phase B-1)
-- 기획서 6장 (DB 스키마) 기반
-- 모든 user-data 테이블에 RLS 적용 (auth.uid() 기반)
-- ============================================================

-- ------------------------------------------------------------
-- 1. users — Supabase Auth와 1:1 매칭 (id = auth.users.id)
-- ------------------------------------------------------------
create table public.users (
    id                       uuid primary key references auth.users on delete cascade,
    nickname                 text not null,
    auth_provider            text not null check (auth_provider in ('kakao', 'apple')),
    push_token               text,
    push_time                time not null default '07:30:00',
    push_enabled             boolean not null default true,
    subscription_status      text not null default 'free'
                                  check (subscription_status in ('free', 'trial', 'premium', 'cancelled')),
    trial_started_at         timestamptz,
    subscription_expires_at  timestamptz,
    created_at               timestamptz not null default now(),
    last_active_at           timestamptz not null default now()
);

alter table public.users enable row level security;

create policy "users_self_read"   on public.users for select using (auth.uid() = id);
create policy "users_self_insert" on public.users for insert with check (auth.uid() = id);
create policy "users_self_update" on public.users for update using (auth.uid() = id);

-- ------------------------------------------------------------
-- 2. saju_profiles — 사주 8글자 + 캐시
-- ------------------------------------------------------------
create table public.saju_profiles (
    id                  uuid primary key default gen_random_uuid(),
    user_id             uuid not null references public.users(id) on delete cascade,
    -- 입력 데이터
    birth_calendar      text not null check (birth_calendar in ('solar', 'lunar')),
    birth_year          smallint not null check (birth_year between 1900 and 2100),
    birth_month         smallint not null check (birth_month between 1 and 12),
    birth_day           smallint not null check (birth_day between 1 and 31),
    birth_hour          smallint check (birth_hour between 0 and 23),
    birth_minute        smallint check (birth_minute between 0 and 59),
    gender              text not null check (gender in ('male', 'female')),
    birth_place         text not null default '서울',
    chinese_name        text,
    -- 만세력 캐시 (양력 변환된 값으로 계산)
    year_pillar         text not null,    -- 예: "庚午"
    month_pillar        text not null,
    day_pillar          text not null,
    hour_pillar         text,
    day_master          text not null,    -- 일간 (예: "戊")
    five_elements_dist  jsonb not null,   -- {"木":2,"火":2,"土":2,"金":2,"水":0}
    ten_gods            jsonb,            -- 십신 분포 (Phase B 후 채움)
    yongshin            text,             -- 용신 (Phase B 후 채움)
    dae_woon            jsonb not null,   -- [{"start_age":9,"pillar":"己未","start_year":1999}, ...]
    created_at          timestamptz not null default now(),
    unique (user_id)                       -- 1 user → 1 profile
);

alter table public.saju_profiles enable row level security;

create policy "saju_self_read"   on public.saju_profiles for select using (auth.uid() = user_id);
create policy "saju_self_insert" on public.saju_profiles for insert with check (auth.uid() = user_id);
create policy "saju_self_update" on public.saju_profiles for update using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 3. daily_fortunes — 매일 운세 (cron이 채움)
-- ------------------------------------------------------------
create table public.daily_fortunes (
    id                       uuid primary key default gen_random_uuid(),
    user_id                  uuid not null references public.users(id) on delete cascade,
    date                     date not null,
    day_pillar_of_date       text not null,
    one_liner                text not null,
    lucky_color_primary      text not null,             -- hex (예: "#C9B8F0")
    lucky_color_secondary    text,
    lucky_direction          text not null check (lucky_direction in ('동쪽', '서쪽', '남쪽', '북쪽', '중앙')),
    lucky_time_start         time not null,
    lucky_time_end           time not null,
    lucky_numbers            smallint[] not null,
    avoid                    text not null,
    generated_at             timestamptz not null default now(),
    ai_model_used            text,
    unique (user_id, date)
);

create index idx_daily_fortunes_user_date on public.daily_fortunes(user_id, date desc);

alter table public.daily_fortunes enable row level security;

create policy "fortune_self_read"   on public.daily_fortunes for select using (auth.uid() = user_id);
create policy "fortune_self_insert" on public.daily_fortunes for insert with check (auth.uid() = user_id);
create policy "fortune_self_update" on public.daily_fortunes for update using (auth.uid() = user_id);
-- Edge Function이 user JWT로 daily-oneliner upsert하기 위함. 본인 row만 가능.

-- ------------------------------------------------------------
-- 4. saju_readings — 단계별 풀이 캐시
-- ------------------------------------------------------------
create table public.saju_readings (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references public.users(id) on delete cascade,
    stage           smallint not null check (stage between 1 and 5),
    content         text not null,
    generated_at    timestamptz not null default now(),
    ai_model_used   text,
    unique (user_id, stage)
);

alter table public.saju_readings enable row level security;

create policy "reading_self_read"   on public.saju_readings for select using (auth.uid() = user_id);
create policy "reading_self_insert" on public.saju_readings for insert with check (auth.uid() = user_id);
create policy "reading_self_update" on public.saju_readings for update using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 5. chat_messages — AI 챗봇 히스토리 (유료 전용)
-- ------------------------------------------------------------
create table public.chat_messages (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references public.users(id) on delete cascade,
    role            text not null check (role in ('user', 'assistant')),
    content         text not null,
    created_at      timestamptz not null default now(),
    ai_model_used   text
);

create index idx_chat_messages_user_created on public.chat_messages(user_id, created_at desc);

alter table public.chat_messages enable row level security;

create policy "chat_self_read"   on public.chat_messages for select using (auth.uid() = user_id);
create policy "chat_self_insert" on public.chat_messages for insert with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 6. push_logs — APNs 발송 기록 (운영 분석용)
-- ------------------------------------------------------------
create table public.push_logs (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references public.users(id) on delete cascade,
    sent_at     timestamptz not null default now(),
    opened_at   timestamptz,
    title       text not null,
    body        text not null
);

create index idx_push_logs_user_sent on public.push_logs(user_id, sent_at desc);

alter table public.push_logs enable row level security;

create policy "push_logs_self_read" on public.push_logs for select using (auth.uid() = user_id);
-- insert는 service_role만. update(opened_at)은 사용자가 직접 X — Edge Function 통해.

-- ------------------------------------------------------------
-- 7. subscriptions — 결제 / 자동갱신 추적
-- ------------------------------------------------------------
create table public.subscriptions (
    id                        uuid primary key default gen_random_uuid(),
    user_id                   uuid not null references public.users(id) on delete cascade,
    plan                      text not null check (plan in ('monthly', 'yearly')),
    provider                  text not null check (provider in ('apple_iap', 'web_portone')),
    provider_subscription_id  text not null,
    started_at                timestamptz not null,
    current_period_end        timestamptz not null,
    cancelled_at              timestamptz,
    created_at                timestamptz not null default now(),
    unique (provider, provider_subscription_id)
);

create index idx_subscriptions_user on public.subscriptions(user_id);

alter table public.subscriptions enable row level security;

create policy "subscriptions_self_read" on public.subscriptions for select using (auth.uid() = user_id);
-- insert/update는 service_role만 (Apple webhook 검증 후).
