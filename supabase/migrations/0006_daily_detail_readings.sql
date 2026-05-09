-- 자세한 일별 운세 (사용자 #2 프롬프트 형식). daily_fortunes(한 줄+행운)와 별개.
-- 사용자가 "자세히 보기" 누를 때만 호출 — lazy load + cache.

create table if not exists public.daily_detail_readings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  content text not null,
  prompt_version int not null default 1,
  ai_model_used text,
  created_at timestamptz not null default now(),
  unique (user_id, date)
);

alter table public.daily_detail_readings enable row level security;

create policy "Users can read own daily detail readings"
  on public.daily_detail_readings for select
  using (auth.uid() = user_id);

create policy "Users can insert own daily detail readings"
  on public.daily_detail_readings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own daily detail readings"
  on public.daily_detail_readings for update
  using (auth.uid() = user_id);

create index if not exists daily_detail_readings_user_date_idx
  on public.daily_detail_readings (user_id, date desc);
