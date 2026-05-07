-- 멀티사주 제거 (Phase 1 후속). 0003에서 partial index로 바꿨던 걸 단순 unique로 복구.
-- saju_profiles에 user당 1 row만 허용 (본인 사주 1개).
-- 본인 외 row가 이미 있는 운영 DB라면 사전 정리 필요 (현재는 본인만 가정).

drop index if exists public.saju_profiles_owner_unique;

alter table public.saju_profiles
  add constraint saju_profiles_user_id_key unique (user_id);
