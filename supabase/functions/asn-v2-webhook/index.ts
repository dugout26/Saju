// Apple App Store Server Notifications V2 — webhook 수신 endpoint.
//
// POST /functions/v1/asn-v2-webhook
//   - 인증 헤더 없음 (Apple → us). signedPayload JWS는 trigger 용도로만 사용.
//   - body: { signedPayload: string }
//
// Trust 모델:
// signedPayload의 JWS 서명 (x5c chain) 검증은 구현하지 않음. 대신 모든 액션 결정은
// **Apple App Store Server API에서 재조회한 trusted transaction state**로부터 도출.
// notification.notificationType / data.bundleId 등은 untrusted로 간주 — transactionId
// 추출에만 사용. 위조 payload가 들어와도 trusted state가 변하지 않으면 DB는 안 바뀜.
//
// 처리 흐름:
// 1. signedPayload decode (untrusted) → signedTransactionInfo
// 2. signedTransactionInfo decode (untrusted) → transactionId
// 3. App Store Server API /inApps/v1/transactions/{id} 호출 (signed by Apple) → trusted
// 4. trusted bundleId/productId 검증 + revocation/expiration으로 action 도출
// 5. originalTransactionId로 user 매핑 → users + subscriptions 갱신
//
// 응답 (Apple ASN v2 retry: 5회, 1h/12h/24h/48h/72h):
//   200 → 처리 완료 / 무시 (idempotent — 중복 webhook도 안전)
//   500 → 내부 오류 (DB write 실패 등) → Apple retry
//   503 → ASC key 미설정, Apple API 일시적 장애 (429/5xx), mapping 미존재 → Apple retry
//   400/403/404 → 영구 실패 (재시도 안 함)

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create as createJWT } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import { corsHeaders, jsonError } from "../_shared/cors.ts";

interface RequestBody { signedPayload: string; }

interface NotificationPayload {
  notificationType: string;
  subtype?: string;
  notificationUUID: string;
  data: {
    appAppleId?: number;
    bundleId: string;
    environment: string;       // "Sandbox" | "Production"
    signedTransactionInfo: string;
    signedRenewalInfo?: string;
  };
  version: string;
  signedDate: number;
}

interface TransactionPayload {
  bundleId: string;
  productId: string;
  transactionId: string;
  originalTransactionId: string;
  purchaseDate: number;
  expiresDate?: number;
  environment?: string;
  type?: string;
  inAppOwnershipType?: string;
  appAccountToken?: string;
  revocationDate?: number;
  revocationReason?: number;   // 0 = other, 1 = refund (App Store)
}

const ALLOWED_BUNDLE_ID = "kr.mound.unse";
const ALLOWED_PRODUCT_IDS = ["unse.monthly", "unse.yearly"];

// JWS / JWT는 base64url 인코딩 — 패딩 누락 시 atob() 실패 케이스 보정.
function decodeJWSPayload<T>(jws: string): T | null {
  const parts = jws.split(".");
  if (parts.length !== 3) return null;
  try {
    const base64url = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64url + "=".repeat((4 - base64url.length % 4) % 4);
    return JSON.parse(atob(padded)) as T;
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
      exp: now + 60 * 20,
      aud: "appstoreconnect-v1",
      bid: ALLOWED_BUNDLE_ID,
    },
    cryptoKey,
  );
}

// fetchTrustedTransaction 결과 — Apple API 응답을 retryable 여부로 분류.
// transient: Apple이 retry queue에 보관 (503).
// not_found: 영구 실패 (404).
// ok: trusted payload 사용 가능.
type FetchResult =
  | { kind: "ok"; payload: TransactionPayload }
  | { kind: "not_found" }
  | { kind: "transient" };

async function fetchTrustedTransaction(
  transactionId: string,
  environment: string,
): Promise<FetchResult> {
  const jwt = await appStoreServerJWT();
  if (!jwt) return { kind: "transient" };

  const baseUrl = environment === "Sandbox"
    ? "https://api.storekit-sandbox.itunes.apple.com"
    : "https://api.storekit.itunes.apple.com";

  let res: Response;
  try {
    res = await fetch(
      `${baseUrl}/inApps/v1/transactions/${transactionId}`,
      { headers: { Authorization: `Bearer ${jwt}` } },
    );
  } catch (e) {
    // network error → transient
    console.error("[asn-v2-webhook] App Store API fetch error:", e);
    return { kind: "transient" };
  }

  // 4040010 (TransactionIdNotFoundError) 포함 404 → 영구 실패.
  if (res.status === 404) return { kind: "not_found" };
  // 429 + 5xx → 일시적, Apple retry 큐에서 재시도 가능.
  if (res.status === 429 || res.status >= 500) {
    console.warn("[asn-v2-webhook] App Store API transient:", res.status);
    return { kind: "transient" };
  }
  // 그 외 4xx (400/401/403) → key/auth 문제로 영구 실패.
  if (!res.ok) {
    console.error("[asn-v2-webhook] App Store API permanent failure:", res.status, await res.text());
    return { kind: "not_found" };
  }

  let json: { signedTransactionInfo: string };
  try {
    json = await res.json();
  } catch {
    return { kind: "transient" };
  }
  const payload = decodeJWSPayload<TransactionPayload>(json.signedTransactionInfo);
  if (!payload) return { kind: "transient" };
  return { kind: "ok", payload };
}

type DBAction = "activate" | "cancel";

// trusted transaction state → DB action.
// revocationDate 있으면 환불/회수, expiresDate 지났으면 만료 → cancel.
// 그 외 → activate (premium).
function deriveAction(tx: TransactionPayload): DBAction {
  if (tx.revocationDate) return "cancel";
  // auto-renewable subscription은 expiresDate 필수. 누락된 trusted tx는 비정상 →
  // activate 분기에서 400으로 폐기되면 Apple retry 안 함. 여기서 cancel로 분류.
  if (!tx.expiresDate) return "cancel";
  if (tx.expiresDate <= Date.now()) return "cancel";
  return "activate";
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const body = await req.json() as RequestBody;
    if (!body.signedPayload) return jsonError("signedPayload required", 400);

    // 1. Untrusted decode — transactionId 추출 용도로만 사용.
    const notification = decodeJWSPayload<NotificationPayload>(body.signedPayload);
    if (!notification?.data?.signedTransactionInfo) {
      return jsonError("Invalid signedPayload structure", 400);
    }

    const claimedTx = decodeJWSPayload<TransactionPayload>(notification.data.signedTransactionInfo);
    if (!claimedTx?.transactionId) {
      return jsonError("Invalid signedTransactionInfo", 400);
    }

    // 2. ASC key 미설정 시 fail-closed (Apple retry 큐로 시간 확보).
    if (!Deno.env.get("ASC_PRIVATE_KEY")) {
      return jsonError("ASC_PRIVATE_KEY not configured", 503);
    }

    // 3. Trusted fetch — App Store Server API가 signed by Apple.
    const fetchResult = await fetchTrustedTransaction(
      claimedTx.transactionId,
      notification.data.environment ?? "Production",
    );
    if (fetchResult.kind === "transient") {
      return jsonError("Apple API transient failure", 503);
    }
    if (fetchResult.kind === "not_found") {
      return jsonError("Transaction not found at Apple", 404);
    }
    const trustedTx = fetchResult.payload;

    // 4. Trusted bundleId / productId / environment 검증.
    if (trustedTx.bundleId !== ALLOWED_BUNDLE_ID) {
      return jsonError("bundle_id mismatch (trusted)", 403);
    }
    if (!ALLOWED_PRODUCT_IDS.includes(trustedTx.productId)) {
      return jsonError("product not allowed (trusted)", 403);
    }
    // environment 교차 검증 — untrusted notification.data.environment로 sandbox/prod
    // namespace를 가르는 것을 trusted payload로 다시 확인. (실 exploit 어려우나 명시적.)
    const claimedEnv = notification.data.environment ?? "Production";
    if (trustedTx.environment && trustedTx.environment !== claimedEnv) {
      return jsonError("environment mismatch", 403);
    }

    // 5. Action을 trusted state에서 도출 — notification.notificationType은 신뢰 불가.
    const action = deriveAction(trustedTx);

    // 6. originalTransactionId → user 매핑 (verify-receipt 시점에 저장됨).
    const url = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, serviceKey);

    const { data: subRow, error: subErr } = await admin
      .from("subscriptions")
      .select("user_id, started_at")
      .eq("provider", "apple_iap")
      .eq("provider_subscription_id", trustedTx.originalTransactionId)
      .maybeSingle();

    if (subErr) {
      console.error("[asn-v2-webhook] subscriptions lookup failed:", subErr);
      return jsonError("subscription lookup failed", 500);
    }
    if (!subRow) {
      // verify-receipt 호출 전 ASN이 먼저 도착한 케이스 — 503으로 retry 큐에 보관.
      console.warn(
        "[asn-v2-webhook] subscription mapping not found:",
        trustedTx.originalTransactionId,
      );
      return jsonError("subscription mapping not found", 503);
    }
    const userId = subRow.user_id;

    // 7. 액션별 갱신.
    const expiresAtIso = trustedTx.expiresDate
      ? new Date(trustedTx.expiresDate).toISOString()
      : null;

    if (action === "activate") {
      // deriveAction이 expiresDate 누락을 cancel로 처리하므로 여기는 항상 set.
      // 그래도 명시적 invariant.
      if (!expiresAtIso) {
        return jsonError("activate without expiresDate", 500);
      }
      const userUpdate = await admin
        .from("users")
        .update({
          subscription_status: "premium",
          subscription_expires_at: expiresAtIso,
        })
        .eq("id", userId);
      if (userUpdate.error) {
        console.error("[asn-v2-webhook] users update failed:", userUpdate.error);
        return jsonError("users update failed", 500);
      }

      // started_at은 최초 구매일 보존 — 갱신마다 purchaseDate로 덮어쓰지 않음.
      const startedAtIso = subRow.started_at
        ?? new Date(trustedTx.purchaseDate).toISOString();
      const plan = trustedTx.productId.includes("monthly") ? "monthly" : "yearly";
      const subUpsert = await admin
        .from("subscriptions")
        .upsert({
          user_id: userId,
          plan,
          provider: "apple_iap",
          provider_subscription_id: trustedTx.originalTransactionId,
          started_at: startedAtIso,
          current_period_end: expiresAtIso,
          cancelled_at: null,
        }, { onConflict: "provider,provider_subscription_id" });
      if (subUpsert.error) {
        console.error("[asn-v2-webhook] subscriptions upsert failed:", subUpsert.error);
        return jsonError("subscriptions upsert failed", 500);
      }
    } else {
      // cancel — refund / revoke / expired 모두 동일하게 cancelled로 표기.
      // expiresAtIso가 null이면 (revocationDate만 있는 케이스) 기존 값 유지.
      const userUpdatePayload: Record<string, string> = {
        subscription_status: "cancelled",
      };
      if (expiresAtIso) {
        userUpdatePayload.subscription_expires_at = expiresAtIso;
      }
      const userUpdate = await admin
        .from("users")
        .update(userUpdatePayload)
        .eq("id", userId);
      if (userUpdate.error) {
        console.error("[asn-v2-webhook] users cancel failed:", userUpdate.error);
        return jsonError("users update failed", 500);
      }

      const cancelledAt = trustedTx.revocationDate
        ? new Date(trustedTx.revocationDate).toISOString()
        : new Date().toISOString();
      const subUpdate = await admin
        .from("subscriptions")
        .update({ cancelled_at: cancelledAt })
        .eq("provider", "apple_iap")
        .eq("provider_subscription_id", trustedTx.originalTransactionId);
      if (subUpdate.error) {
        console.error("[asn-v2-webhook] subscriptions cancel failed:", subUpdate.error);
        return jsonError("subscriptions update failed", 500);
      }
    }

    console.info(
      "[asn-v2-webhook] processed:",
      "action:", action,
      "user:", userId,
      "uuid:", notification.notificationUUID,
      "type-claimed:", notification.notificationType,
    );

    return new Response(
      JSON.stringify({ ok: true, action }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[asn-v2-webhook] unexpected error:", e);
    return jsonError("webhook 처리 중 오류 발생", 500);
  }
});
