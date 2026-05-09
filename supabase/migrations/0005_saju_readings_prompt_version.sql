-- saju_readings에 prompt_version 컬럼 추가.
-- prompt가 바뀌면 PROMPT_VERSION 상수만 올리면 자동 cache invalidation
-- (옛 row는 default 1로 채워지고 Edge Function이 새 버전 요구 시 cache miss → 재호출).

alter table public.saju_readings
  add column if not exists prompt_version int not null default 1;

-- 기존 row는 v1으로 마킹 (이번 변경된 prompt는 v2부터).
update public.saju_readings set prompt_version = 1 where prompt_version is null;
