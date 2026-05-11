-- 매일 운세 push cron — pg_cron이 매 30분마다 send-push Edge Function을 호출.
-- send-push 내부에서 push_time이 현재 30분 윈도우 안 user들에게 발송 (sendDaily 분기).
--
-- 사전 작업 (사용자 수동 — Supabase Dashboard 또는 SQL editor):
-- 1. Database → Extensions → pg_cron, pg_net 활성화
-- 2. Vault에 service_role_key 등록:
--      select vault.create_secret(
--        '<여기에 실제 service_role JWT>',
--        'service_role_key'
--      );
-- 3. project URL 등록:
--      select vault.create_secret(
--        'https://<project-ref>.supabase.co',
--        'project_url'
--      );
-- 4. 본 마이그레이션 적용 (supabase db push 또는 SQL editor).
--
-- 결과: 매 30분 자동 호출 → push_time 매칭 user들에게 daily push 발송.
-- 비활성화: select cron.unschedule('send-daily-push');

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 기존 동일 job 있으면 제거 (재실행 safe).
select cron.unschedule(jobid) from cron.job where jobname = 'send-daily-push';

select cron.schedule(
  'send-daily-push',
  '*/30 * * * *',   -- 매 30분 (00, 30분 시작점)
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')
    ),
    body := jsonb_build_object('type', 'daily'),
    timeout_milliseconds := 30000
  ) as request_id;
  $$
);
