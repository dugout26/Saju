-- 멀티 사주 (본인 + 추가 가족·친구). saju_profiles를 1:1 → 1:N 으로 확장.
-- relation='본인' row는 user당 1개만 (partial unique index).

alter table public.saju_profiles
  add column if not exists display_name      text not null default '본인',
  add column if not exists relation          text not null default '본인',
  add column if not exists last_modified_at  timestamptz not null default now();

-- 기존 1:1 unique constraint 제거
alter table public.saju_profiles drop constraint if exists saju_profiles_user_id_key;

-- 본인 사주는 user당 1개만 보장
create unique index if not exists saju_profiles_owner_unique
  on public.saju_profiles (user_id)
  where relation = '본인';

-- relation 값 제한
alter table public.saju_profiles
  add constraint saju_profiles_relation_check
  check (relation in ('본인', '가족', '친구', '연인', '기타'));
