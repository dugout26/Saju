// StoreKit 2 영수증 (signed transaction JWS) 서버 검증.
//
// POST /functions/v1/verify-receipt
// Authorization: Bearer <user JWT>
// body: { signed_transaction: string }  // Transaction.jwsRepresentation
// response: { is_premium: bool, subscription_status: string, expires_at: number? }
//
// 검증 흐름 (단계 2 — App Store Server API 정공):
// 1. 클라이언트 JWS payload decode (untrusted — transactionId만 추출)
// 2. App Store Server API JWT (ES256) 생성 → /inApps/v1/transactions/{id} 호출
// 3. Apple이 signedTransactionInfo (JWS) 반환 — trusted
// 4. trusted payload로 bundleId/productId/expires 검증
// 5. service_role로 users + subscriptions 갱신 (트랜잭션 정합성 보장)
//
// .p8 key (ASC_PRIVATE_KEY/ASC_KEY_ID/ASC_ISSUER_ID) 미설정 시 503 (fail-closed).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create as createJWT } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import { corsHeaders, jsonError } from "../_shared/cors.ts";

interface RequestBody { signed_transaction: string; }

interface JWSPayload {
  bundleId: string;
  productId: string;
  transactionId: string;
  originalTransactionId: string;
  purchaseDate: number;
  expiresDate?: number;
  environment?: string;          // "Sandbox" | "Production"
  type?: string;
  inAppOwnershipType?: string;
}

const ALLOWED_BUNDLE_ID = "kr.mound.unse";
const ALLOWED_PRODUCT_IDS = ["unse.monthly", "unse.yearly"];

// JWS / JWT는 base64url 인코딩 — 패딩 누락 시 atob() 실패 케이스 보정.
function decodeJWSPayload(jws: string): JWSPayload | null {
  const parts = jws.split(".");
  if (parts.length !== 3) return null;
  try {
    const base64url = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64url + "=".repeat((4 - base64url.length % 4) % 4);
    return JSON.parse(atob(padded));
  } catch {
    return null;
  }
}

// PEM .p8 → ECDSA P-256 CryptoKey (App Store Server API JWT 서명용)
async function importP8PrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryDer = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

async function appStoreServerJWT(): Promise<string | null> {
  const keyId = Deno.env.get("ASC_KEY_ID");
  const issuerId = Deno.env.get("ASC_ISSUER_ID");
  const pem = Deno.env.get("ASC_PRIVATE_KEY");
  if (!keyId || !issuerId || !pem) return null;

  const cryptoKey = await importP8PrivateKey(pem);
  const now = Math.floor(Date.now() / 1000);
  return await createJWT(
    { alg: "ES256", kid: keyId, typ: "JWT" },
    {
      iss: issuerId,
      iat: now,
      exp: now + 60 * 20, // 20분
      aud: "appstoreconnect-v1",
      bid: ALLOWED_BUNDLE_ID,
    },
    cryptoKey,
  );
}

async function fetchTrustedTransaction(
  transactionId: string,
  environment: string,
): Promise<JWSPayload | null> {
  const jwt = await appStoreServerJWT();
  if (!jwt) return null;

  const baseUrl = environment === "Sandbox"
    ? "https://api.storekit-sandbox.itunes.apple.com"
    : "https://api.storekit.itunes.apple.com";

  const res = await fetch(
    `${baseUrl}/inApps/v1/transactions/${transactionId}`,
    { headers: { Authorization: `Bearer ${jwt}` } },
  );
  if (!res.ok) {
    console.error("[verify-receipt] App Store Server API failed:", res.status, await res.text());
    return null;
  }

  const json = await res.json() as { signedTransactionInfo: string };
  return decodeJWSPayload(json.signedTransactionInfo);
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const auth = req.headers.get("Authorization");
    if (!auth) return jsonError("Authorization required", 401);

    const body = await req.json() as RequestBody;
    if (!body.signed_transaction) return jsonError("signed_transaction required", 400);

    // 1. 클라이언트 JWS decode — transactionId / environment 추출용 (untrusted).
    const clientPayload = decodeJWSPayload(body.signed_transaction);
    if (!clientPayload) return jsonError("Invalid JWS format", 400);

    // 2. App Store Server API로 trusted transaction fetch.
    //    .p8 key 미설정 시 fail-closed (503) — fake security 회피.
    if (!Deno.env.get("ASC_PRIVATE_KEY")) {
      return jsonError(
        "App Store Server API key 미설정 — ASC_PRIVATE_KEY, ASC_KEY_ID, ASC_ISSUER_ID Supabase secrets에 설정 필요.",
        503,
      );
    }
    const trustedPayload = await fetchTrustedTransaction(
      clientPayload.transactionId,
      clientPayload.environment ?? "Production",
    );
    if (!trustedPayload) {
      return jsonError("Transaction not verifiable at App Store", 404);
    }

    // 3. Trusted payload로 검증 (Apple이 직접 서명).
    if (trustedPayload.bundleId !== ALLOWED_BUNDLE_ID) {
      return jsonError("bundle_id mismatch", 403);
    }
    if (!ALLOWED_PRODUCT_IDS.includes(trustedPayload.productId)) {
      return jsonError("product not allowed", 403);
    }

    const now = Date.now();
    const isActive = trustedPayload.expiresDate ? trustedPayload.expiresDate > now : false;

    // 4. user 인증 (Authorization JWT로 user.id 추출).
    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: auth } },
    });
    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) return jsonError("Unauthorized", 401);

    // 5. service_role로 users + subscriptions 갱신 (정합성 보장 — 둘 중 하나 실패하면 500).
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, serviceKey);

    const subscriptionStatus = isActive ? "premium" : "cancelled";
    const expiresAt = trustedPayload.expiresDate
      ? new Date(trustedPayload.expiresDate).toISOString()
      : null;

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

    const plan = trustedPayload.productId.includes("monthly") ? "monthly" : "yearly";
    const subUpsert = await admin
      .from("subscriptions")
      .upsert({
        user_id: user.id,
        plan,
        provider: "apple_iap",
        provider_subscription_id: trustedPayload.originalTransactionId,
        started_at: new Date(trustedPayload.purchaseDate).toISOString(),
        current_period_end: expiresAt,
      }, { onConflict: "provider,provider_subscription_id" });
    if (subUpsert.error) {
      // users는 이미 갱신됐는데 subscriptions 실패 = 정합성 깨짐. 500 응답.
      console.error("[verify-receipt] subscriptions upsert failed:", subUpsert.error);
      return jsonError("구독 이력 저장 중 오류가 발생했어요. 다시 시도해 주세요.", 500);
    }

    return new Response(
      JSON.stringify({
        is_premium: isActive,
        subscription_status: subscriptionStatus,
        expires_at: trustedPayload.expiresDate ?? null,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[verify-receipt] unexpected error:", e);
    return jsonError("영수증 검증 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.", 500);
  }
});
