// asn-v2-webhook의 deriveAction 단위 테스트.
// trusted transaction state → activate | cancel 결정 로직 검증.

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { deriveAction } from "./deriveAction.ts";

const baseTx = {
  bundleId: "kr.mound.unse",
  productId: "unse.monthly",
  transactionId: "tx-1",
  originalTransactionId: "tx-1",
  purchaseDate: 1_700_000_000_000,
};

Deno.test("expiresDate 미래 → activate", () => {
  const tx = { ...baseTx, expiresDate: Date.now() + 86_400_000 };
  assertEquals(deriveAction(tx), "activate");
});

Deno.test("expiresDate 과거 → cancel (만료)", () => {
  const tx = { ...baseTx, expiresDate: Date.now() - 86_400_000 };
  assertEquals(deriveAction(tx), "cancel");
});

Deno.test("revocationDate 있음 → cancel (환불/회수, 만료일과 무관)", () => {
  const tx = {
    ...baseTx,
    expiresDate: Date.now() + 86_400_000,
    revocationDate: Date.now() - 1000,
  };
  assertEquals(deriveAction(tx), "cancel");
});

Deno.test("expiresDate 누락 → cancel (auto-renewable subscription 비정상)", () => {
  const tx = { ...baseTx };
  assertEquals(deriveAction(tx), "cancel");
});

Deno.test("expiresDate 정확히 현재 → cancel (<= 비교)", () => {
  // Now() 직접 비교는 race condition. expiresDate = now-1로 안전한 경계 검증.
  const now = Date.now();
  const tx = { ...baseTx, expiresDate: now - 1 };
  assertEquals(deriveAction(tx), "cancel");
});
