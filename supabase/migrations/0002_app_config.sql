-- 앱 전역 설정 (단일 row 보장).
-- 강제 업데이트 + 스토어 URL 관리.

create table public.app_config (
    id                   smallint primary key default 1,
    min_ios_version      text not null default '1.0.0',
    min_android_version  text not null default '1.0.0',
    app_store_url        text,           -- 출시 후 채움
    play_store_url       text,
    force_update_message text not null default '새 버전이 있습니다. 업데이트해주세요.',
    updated_at           timestamptz not null default now(),
    constraint app_config_singleton check (id = 1)
);

-- 누구나 읽기 가능 (anon도 OK), 쓰기는 service_role만
alter table public.app_config enable row level security;
create policy "config_public_read" on public.app_config for select using (true);

-- 초기 row
insert into public.app_config (id) values (1);
