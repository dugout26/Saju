// Push 발송 admin endpoint. 두 가지 type:
// 1. type=daily — pg_cron이 매 30분 호출. push_time이 현재 윈도우 안 user에게 매일 운세 푸시.
// 2. type=update — manual 호출. 모든 push_token 보유 사용자에게 강제 업데이트 알림.
//
// POST /functions/v1/send-push
// Authorization: Bearer <SERVICE_ROLE_KEY>
// body:
//   { "type": "daily" }
//   { "type": "update", "title": "...", "body": "...", "store_url": "..." }
//   { "type": "test", "user_id": "...", "title": "...", "body": "..." }   // 단일 user 테스트

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonError } from "../_shared/cors.ts";
import { sendFCM } from "../_shared/fcm.ts";

interface RequestBody {
  type: "daily" | "update" | "test";
  title?: string;
  body?: string;
  store_url?: string;
  user_id?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    // 인증 — JWT decode로 role=service_role 확인 (Supabase가 새 key 형식 mix 가능)
    const auth = req.headers.get("Authorization") ?? "";
    const token = auth.replace(/^Bearer\s+/i, "").trim();
    let isAuthorized = false;
    try {
      const parts = token.split(".");
      if (parts.length === 3) {
        const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
        isAuthorized = payload.role === "service_role";
      }
    } catch { /* fall through */ }
    if (!isAuthorized) {
      // Fallback: SUPABASE_SERVICE_ROLE_KEY env var 직접 비교
      const sk = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
      isAuthorized = sk.length > 0 && token === sk;
    }
    if (!isAuthorized) return jsonError("Unauthorized — service_role required", 401);

    const body = await req.json() as RequestBody;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      serviceRoleKey
    );

    let results: Array<{ user_id: string; ok: boolean; status: number }> = [];

    switch (body.type) {
      case "daily":
        results = await sendDaily(supabase);
        break;
      case "update":
        results = await sendUpdate(supabase, body);
        break;
      case "test":
        if (!body.user_id) return jsonError("user_id required", 400);
        results = await sendTest(supabase, body);
        break;
      default:
        return jsonError("Invalid type", 400);
    }

    return new Response(JSON.stringify({
      sent: results.filter((r) => r.ok).length,
      failed: results.filter((r) => !r.ok).length,
      total: results.length,
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return jsonError((e as Error).message, 500);
  }
});

/// 매 30분 cron 호출. push_time이 현재 30분 윈도우 안 user들에게 발송.
async function sendDaily(supabase: any) {
  // 현재 시각 (KST = UTC+9)
  const nowUtc = new Date();
  const nowKst = new Date(nowUtc.getTime() + 9 * 3600_000);
  const hh = nowKst.getUTCHours();
  const mm = nowKst.getUTCMinutes();

  // 현재 윈도우: 정시~30분 또는 30분~정시 (30분 단위).
  // 23:30~24:00 윈도우는 windowEnd가 자정 넘어가서 push_time 문자열 비교가
  // 깨짐 ("23:30" < "00:00" false) — 이 경우 gte만 적용 (해당 시간대 전체 매칭).
  const windowStart = mm < 30
    ? `${pad(hh)}:00:00`
    : `${pad(hh)}:30:00`;
  const windowEnd: string | null = mm < 30
    ? `${pad(hh)}:30:00`
    : hh === 23
      ? null
      : `${pad(hh + 1)}:00:00`;

  let usersQuery = supabase
    .from("users")
    .select("id, nickname, push_token")
    .eq("push_enabled", true)
    .not("push_token", "is", null)
    .gte("push_time", windowStart);
  if (windowEnd !== null) {
    usersQuery = usersQuery.lt("push_time", windowEnd);
  }
  const { data: users, error } = await usersQuery;

  if (error || !users || users.length === 0) return [];

  // 오늘 날짜 (KST) — daily_fortunes 캐시 lookup용.
  const todayKst = `${nowKst.getUTCFullYear()}-${pad(nowKst.getUTCMonth() + 1)}-${pad(nowKst.getUTCDate())}`;

  // 배치 lookup: 50명 = 1 SELECT (개별 50 SELECT 대신).
  const userIds = users.map((u: { id: string }) => u.id);
  const { data: fortunes } = await supabase
    .from("daily_fortunes")
    .select("user_id, one_liner")
    .in("user_id", userIds)
    .eq("date", todayKst);
  const fortuneByUser = new Map<string, string>(
    (fortunes ?? []).map((f: { user_id: string; one_liner: string }) => [f.user_id, f.one_liner]),
  );

  const results: Array<{ user_id: string; ok: boolean; status: number }> = [];
  const logs: Array<{ user_id: string; title: string; body: string }> = [];
  const title = "오늘의 운세 도착";

  for (const user of users) {
    const oneLiner = fortuneByUser.get(user.id);
    const body = oneLiner
      ? `☀️ ${user.nickname}님 — ${oneLiner}`
      : `☀️ ${user.nickname}님, 오늘의 행운 색과 한 줄 운세를 확인해보세요`;

    const result = await sendFCM({
      token: user.push_token,
      title,
      body,
      data: { type: "open_daily" },
    });
    results.push({ user_id: user.id, ok: result.ok, status: result.status });
    logs.push({ user_id: user.id, title, body });
  }

  // 배치 insert: 50명 = 1 INSERT (개별 50 INSERT 대신).
  if (logs.length > 0) {
    await supabase.from("push_logs").insert(logs);
  }

  return results;
}

async function sendUpdate(supabase: any, body: RequestBody) {
  const title = body.title ?? "새 버전 업데이트";
  const msg = body.body ?? "더 정확한 사주 풀이가 추가됐어요!";
  const storeUrl = body.store_url ?? "";

  const { data: users } = await supabase
    .from("users")
    .select("id, push_token")
    .eq("push_enabled", true)
    .not("push_token", "is", null);

  if (!users) return [];

  const results = [];
  for (const user of users) {
    const result = await sendFCM({
      token: user.push_token,
      title,
      body: msg,
      data: { type: "open_store", url: storeUrl },
    });
    results.push({ user_id: user.id, ok: result.ok, status: result.status });
  }
  return results;
}

async function sendTest(supabase: any, body: RequestBody) {
  const { data: user } = await supabase
    .from("users")
    .select("id, push_token")
    .eq("id", body.user_id)
    .single();

  if (!user || !user.push_token) return [];

  const result = await sendFCM({
    token: user.push_token,
    title: body.title ?? "테스트 알림",
    body: body.body ?? "FCM 연결 확인 메시지",
    data: { type: "test" },
  });
  return [{ user_id: user.id, ok: result.ok, status: result.status }];
}

function pad(n: number): string {
  return n.toString().padStart(2, "0");
}
