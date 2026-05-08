// 카카오 access_token → Supabase magic-link token_hash.
// 클라이언트가 받은 token_hash로 verifyOTP 하면 표준 Supabase 세션 획득.
//
// POST /functions/v1/kakao-auth
// body: { access_token: string }
// response: { token_hash: string, email: string }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonError } from "../_shared/cors.ts";

interface RequestBody { access_token: string; }

interface KakaoMe {
  id: number;
  kakao_account?: {
    profile?: { nickname?: string };
    email?: string;
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const body = await req.json() as RequestBody;
    if (!body.access_token) return jsonError("access_token required", 400);

    // 1. 카카오 토큰 검증
    const kakaoRes = await fetch("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${body.access_token}` },
    });
    if (!kakaoRes.ok) return jsonError("Invalid Kakao token", 401);
    const kakao = await kakaoRes.json() as KakaoMe;
    if (!kakao.id) return jsonError("Kakao user id missing", 400);

    const email = `kakao_${kakao.id}@kakao.unse.local`;
    const nickname = kakao.kakao_account?.profile?.nickname ?? "사용자";

    // 2. service_role admin client
    const url = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, serviceKey);

    // 3. user 없으면 생성 (이미 있으면 conflict 에러를 무시)
    const created = await admin.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: {
        kakao_id: String(kakao.id),
        nickname,
        provider: "kakao",
      },
    });
    // Supabase admin.createUser는 이미 존재하는 user에 대해 422 status 또는
    // "already_registered" / "user_already_exists" 에러를 반환. 둘 다 정상 케이스로 처리.
    if (created.error) {
      const code = (created.error as any).code ?? "";
      const status = (created.error as any).status ?? 0;
      const isAlreadyExists =
        status === 422 ||
        /already|exists|registered/i.test(created.error.message) ||
        code === "email_exists" ||
        code === "user_already_exists";
      if (!isAlreadyExists) {
        console.error("[kakao-auth] createUser failed:", created.error);
        return jsonError("로그인 처리 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.", 500);
      }
    }

    // 4. magic-link token 발급 (이메일 발송 X, token_hash만 추출)
    const link = await admin.auth.admin.generateLink({
      type: "magiclink",
      email,
    });
    const tokenHash = link.data?.properties?.hashed_token;
    if (link.error || !tokenHash) {
      console.error("[kakao-auth] generateLink failed:", link.error);
      return jsonError("로그인 처리 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.", 500);
    }

    return new Response(JSON.stringify({ token_hash: tokenHash, email }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[kakao-auth] unexpected error:", e);
    return jsonError("로그인 처리 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.", 500);
  }
});
