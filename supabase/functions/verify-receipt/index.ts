// StoreKit 2 영수증 (signed transaction JWS) 서버 검증.
// 클라이언트가 직접 users.subscription_status를 update하던 구조 → 서버가 trust source.
//
// POST /functions/v1/verify-receipt
// Authorization: Bearer <user JWT>
// body: { signed_transaction: string }  // Transaction.jwsRepresentation
// response: { is_premium: bool, subscription_status: string, expires_at: number? }
//
// 보안 강화 단계 (현재 → 완전):
// 1. ✅ JWS payload decode + bundle/product/expires 기본 검증 (현재 구현)
// 2. ⏸ JWS 서명 검증 — Apple X.509 chain 또는 App Store Server API 호출
//    (App Store Server API key .p8 필요 — Apple Developer 별도 생성 후 ASC_PRIVATE_KEY,
//     ASC_KEY_ID, ASC_ISSUER_ID Supabase secrets에 set)
// 3. ⏸ ASN (App Store Server Notifications) v2 webhook으로 갱신/취소 실시간 동기
//
// 1번만으로도 클라이언트 단독 trust보다 훨씬 안전 (server-side bundle/product/expires 강제).
// 2-3번은 .p8 key 셋업 후 별도 PR에서 활성.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonError } from "../_shared/cors.ts";

interface RequestBody { signed_transaction: string; }

interface JWSPayload {
  bundleId: string;
  productId: string;
  transactionId: string;
  originalTransactionId: string;
  purchaseDate: number;
  expiresDate?: number;
  type: string;       // "Auto-Renewable Subscription"
  inAppOwnershipType: string;
}

const ALLOWED_BUNDLE_ID = "kr.mound.unse";
const ALLOWED_PRODUCT_IDS = ["unse.monthly", "unse.yearly"];

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const auth = req.headers.get("Authorization");
    if (!auth) return jsonError("Authorization required", 401);

    const body = await req.json() as RequestBody;
    if (!body.signed_transaction) return jsonError("signed_transaction required", 400);

    // 1. JWS payload decode (header.payload.signature)
    const parts = body.signed_transaction.split(".");
    if (parts.length !== 3) return jsonError("Invalid JWS format", 400);

    let payload: JWSPayload;
    try {
      const payloadJson = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
      payload = JSON.parse(payloadJson);
    } catch {
      return jsonError("JWS payload decode failed", 400);
    }

    // 2. 기본 검증 (bundle, product allowlist)
    if (payload.bundleId !== ALLOWED_BUNDLE_ID) {
      return jsonError("bundle_id mismatch", 403);
    }
    if (!ALLOWED_PRODUCT_IDS.includes(payload.productId)) {
      return jsonError("product not allowed", 403);
    }

    // 3. 활성 여부 — auto-renewable subscription의 expiresDate 미래 확인
    const now = Date.now();
    const isActive = payload.expiresDate ? payload.expiresDate > now : false;

    // 4. user 인증 (Authorization JWT로 user.id 추출)
    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: auth } },
    });
    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) return jsonError("Unauthorized", 401);

    // 5. service_role로 users + subscriptions 갱신 (RLS 우회)
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, serviceKey);

    const subscriptionStatus = isActive ? "premium" : "cancelled";
    const expiresAt = payload.expiresDate ? new Date(payload.expiresDate).toISOString() : null;

    const userUpdate = await admin
      .from("users")
      .update({
        subscription_status: subscriptionStatus,
        subscription_expires_at: expiresAt,
      })
      .eq("id", user.id);
    if (userUpdate.error) {
      console.error("[verify-receipt] users update failed:", userUpdate.error);
      return jsonError("구독 상태 갱신 중 오류가 발생했어요. 다시 시도해 주세요.", 500);
    }

    const plan = payload.productId.includes("monthly") ? "monthly" : "yearly";
    const subUpsert = await admin
      .from("subscriptions")
      .upsert({
        user_id: user.id,
        plan,
        provider: "apple_iap",
        provider_subscription_id: payload.originalTransactionId,
        started_at: new Date(payload.purchaseDate).toISOString(),
        current_period_end: expiresAt,
      }, { onConflict: "provider,provider_subscription_id" });
    if (subUpsert.error) {
      console.error("[verify-receipt] subscriptions upsert failed:", subUpsert.error);
      // users update는 성공했으므로 여기 fail은 200으로 응답 (best-effort upsert)
    }

    return new Response(
      JSON.stringify({
        is_premium: isActive,
        subscription_status: subscriptionStatus,
        expires_at: payload.expiresDate ?? null,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[verify-receipt] unexpected error:", e);
    return jsonError("영수증 검증 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.", 500);
  }
});
