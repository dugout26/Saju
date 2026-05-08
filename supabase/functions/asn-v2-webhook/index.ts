// Apple App Store Server Notifications V2 — webhook 수신 endpoint.
//
// POST /functions/v1/asn-v2-webhook
//   - 인증 헤더 없음 (Apple → us). 검증은 두 단계:
//       1) signedPayload (JWS) decode
//       2) signedTransactionInfo의 transactionId로 App Store Server API 재조회 (trusted)
//   - body: { signedPayload: string }
//
// 처리 흐름:
// 1. signedPayload decode → notificationType + signedTransactionInfo
// 2. signedTransactionInfo decode → transactionId, environment (untrusted)
// 3. App Store Server API /inApps/v1/transactions/{id} 호출 → trusted payload
// 4. trusted bundleId/productId 검증
// 5. notificationType별 액션 (activate/cancel/refund/ignore) 결정
// 6. originalTransactionId로 user 매핑 → users + subscriptions 갱신
//
// 응답:
//   200 → 처리 완료 / 무시
//   503 → ASC key 미설정 또는 mapping 미존재 (Apple retry 큐 보관, 8회까지)
//   400/403/404 → 영구 실패 (Apple은 retry 안 함)
//
// Apple Developer 사전 작업:
//   App Store Connect → My Apps → [Unse] → App Information → App Store Server Notifications
//   Production Server URL: https://<project>.functions.supabase.co/asn-v2-webhook
//   Sandbox Server URL: 동일 URL (environment 필드로 분기)
//   Version: Version 2

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

async function fetchTrustedTransaction(
  transactionId: string,
  environment: string,
): Promise<TransactionPayload | null> {
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
    console.error("[asn-v2-webhook] App Store Server API failed:", res.status, await res.text());
    return null;
  }

  const json = await res.json() as { signedTransactionInfo: string };
  return decodeJWSPayload<TransactionPayload>(json.signedTransactionInfo);
}

type DBAction = "activate" | "cancel" | "refund" | "ignore";

// notificationType + subtype → DB 액션 매핑.
// 참고: https://developer.apple.com/documentation/appstoreservernotifications/notificationtype
function mapNotificationType(type: string): DBAction {
  switch (type) {
    case "SUBSCRIBED":
    case "DID_RENEW":
    case "OFFER_REDEEMED":
      return "activate";
    case "EXPIRED":
    case "REVOKE":
      return "cancel";
    case "REFUND":
      return "refund";
    case "DID_CHANGE_RENEWAL_STATUS":
      // AUTO_RENEW_DISABLED → expiresDate까지는 활성. 만료 후 EXPIRED 알림 옴.
      return "ignore";
    case "DID_FAIL_TO_RENEW":
      // billing retry 또는 GRACE_PERIOD — 현 expiresDate까지 활성. EXPIRED 알림 대기.
      return "ignore";
    default:
      // CONSUMPTION_REQUEST, PRICE_INCREASE, RENEWAL_EXTENDED 등 — 무시.
      return "ignore";
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const body = await req.json() as RequestBody;
    if (!body.signedPayload) return jsonError("signedPayload required", 400);

    // 1. 외부 signed payload decode (untrusted — 분기용).
    const notification = decodeJWSPayload<NotificationPayload>(body.signedPayload);
    if (!notification) return jsonError("Invalid signedPayload JWS", 400);

    if (notification.data?.bundleId !== ALLOWED_BUNDLE_ID) {
      console.warn("[asn-v2-webhook] foreign bundle:", notification.data?.bundleId);
      return jsonError("bundle_id mismatch", 403);
    }

    // 2. signedTransactionInfo decode (untrusted — transactionId 추출).
    const claimedTx = decodeJWSPayload<TransactionPayload>(notification.data.signedTransactionInfo);
    if (!claimedTx) return jsonError("Invalid signedTransactionInfo", 400);

    // 3. App Store Server API로 trusted transaction 재확인.
    //    .p8 key 미설정 시 fail-closed (503). Apple retry 큐에 보관됨.
    if (!Deno.env.get("ASC_PRIVATE_KEY")) {
      return jsonError(
        "ASC_PRIVATE_KEY 미설정 — webhook 처리 불가.",
        503,
      );
    }
    const trustedTx = await fetchTrustedTransaction(
      claimedTx.transactionId,
      notification.data.environment,
    );
    if (!trustedTx) {
      return jsonError("Transaction not verifiable", 404);
    }

    if (trustedTx.bundleId !== ALLOWED_BUNDLE_ID) {
      return jsonError("trusted bundle_id mismatch", 403);
    }
    if (!ALLOWED_PRODUCT_IDS.includes(trustedTx.productId)) {
      return jsonError("trusted product not allowed", 403);
    }

    // 4. 액션 결정.
    const action = mapNotificationType(notification.notificationType);
    if (action === "ignore") {
      console.info(
        "[asn-v2-webhook] ignored:",
        notification.notificationType,
        notification.subtype ?? "",
        notification.notificationUUID,
      );
      return new Response(
        JSON.stringify({ ok: true, action: "ignore" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 5. originalTransactionId → user 매핑 (verify-receipt 시점에 저장됨).
    const url = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, serviceKey);

    const { data: subRow, error: subErr } = await admin
      .from("subscriptions")
      .select("user_id")
      .eq("provider", "apple_iap")
      .eq("provider_subscription_id", trustedTx.originalTransactionId)
      .maybeSingle();

    if (subErr) {
      console.error("[asn-v2-webhook] subscriptions lookup failed:", subErr);
      return jsonError("subscription lookup failed", 500);
    }
    if (!subRow) {
      // verify-receipt 호출 전 ASN이 먼저 도착한 케이스 — Apple retry로 시간 벌기.
      console.warn(
        "[asn-v2-webhook] subscription mapping not found:",
        trustedTx.originalTransactionId,
      );
      return jsonError("subscription mapping not found", 503);
    }
    const userId = subRow.user_id;

    // 6. 액션별 갱신.
    const expiresAtIso = trustedTx.expiresDate
      ? new Date(trustedTx.expiresDate).toISOString()
      : null;

    if (action === "activate") {
      // 활성화는 expiresDate 필수 (auto-renewable subscription).
      if (!expiresAtIso) {
        return jsonError("activate without expiresDate", 400);
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

      const plan = trustedTx.productId.includes("monthly") ? "monthly" : "yearly";
      const subUpsert = await admin
        .from("subscriptions")
        .upsert({
          user_id: userId,
          plan,
          provider: "apple_iap",
          provider_subscription_id: trustedTx.originalTransactionId,
          started_at: new Date(trustedTx.purchaseDate).toISOString(),
          current_period_end: expiresAtIso,
          cancelled_at: null,
        }, { onConflict: "provider,provider_subscription_id" });
      if (subUpsert.error) {
        console.error("[asn-v2-webhook] subscriptions upsert failed:", subUpsert.error);
        return jsonError("subscriptions upsert failed", 500);
      }
    } else {
      // cancel | refund — users는 cancelled, subscriptions는 cancelled_at 마킹.
      const userUpdate = await admin
        .from("users")
        .update({
          subscription_status: "cancelled",
          subscription_expires_at: expiresAtIso,
        })
        .eq("id", userId);
      if (userUpdate.error) {
        console.error("[asn-v2-webhook] users cancel failed:", userUpdate.error);
        return jsonError("users update failed", 500);
      }

      const subUpdate = await admin
        .from("subscriptions")
        .update({
          cancelled_at: new Date().toISOString(),
        })
        .eq("provider", "apple_iap")
        .eq("provider_subscription_id", trustedTx.originalTransactionId);
      if (subUpdate.error) {
        console.error("[asn-v2-webhook] subscriptions cancel failed:", subUpdate.error);
        return jsonError("subscriptions update failed", 500);
      }
    }

    console.info(
      "[asn-v2-webhook] processed:",
      notification.notificationType,
      "action:", action,
      "user:", userId,
      "uuid:", notification.notificationUUID,
    );

    return new Response(
      JSON.stringify({ ok: true, action, notificationType: notification.notificationType }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[asn-v2-webhook] unexpected error:", e);
    return jsonError("webhook 처리 중 오류 발생", 500);
  }
});
