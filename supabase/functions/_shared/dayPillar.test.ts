// Manse.swift의 computeDayPillar과 동일 결과를 producing하는지 검증.
// Reference: JDN 2451545 (2000-01-01 UTC) = 戊午 (60갑자 idx 54).

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { dayPillarOfDate } from "./dayPillar.ts";

// dayPillarOfDate는 입력 Date의 KST 자정 기준 일진. KST = UTC+9이므로
// UTC 기준으로 "전날 15:00Z"가 KST 자정에 해당.

Deno.test("2000-01-01 KST 자정 = 戊午 (reference)", () => {
  // KST 2000-01-01 00:00 == UTC 1999-12-31 15:00
  const kstMidnight = new Date("1999-12-31T15:00:00Z");
  assertEquals(dayPillarOfDate(kstMidnight), "戊午");
});

Deno.test("2000-01-02 KST = 己未 (60갑자 idx 55)", () => {
  const kstMidnight = new Date("2000-01-01T15:00:00Z");
  assertEquals(dayPillarOfDate(kstMidnight), "己未");
});

Deno.test("60일 후 같은 일진 반복 (60갑자 순환)", () => {
  const base = new Date("1999-12-31T15:00:00Z");
  const after60 = new Date(base.getTime() + 60 * 86400_000);
  assertEquals(dayPillarOfDate(base), dayPillarOfDate(after60));
});

Deno.test("연속 60일 unique — 모든 60갑자 등장", () => {
  const base = new Date("1999-12-31T15:00:00Z");
  const pillars = new Set<string>();
  for (let i = 0; i < 60; i++) {
    pillars.add(dayPillarOfDate(new Date(base.getTime() + i * 86400_000)));
  }
  assertEquals(pillars.size, 60);
});

Deno.test("KST 경계: UTC 14:59:59 → 어제 일진", () => {
  // KST 2000-01-01 23:59:59 == UTC 2000-01-01 14:59:59
  const justBeforeMidnight = new Date("2000-01-01T14:59:59Z");
  // KST 자정 기준이므로 still 2000-01-01 KST = 戊午
  assertEquals(dayPillarOfDate(justBeforeMidnight), "戊午");
});

Deno.test("KST 경계: UTC 15:00 → 다음날 일진", () => {
  // KST 2000-01-02 00:00 == UTC 2000-01-01 15:00
  const nextKstMidnight = new Date("2000-01-01T15:00:00Z");
  assertEquals(dayPillarOfDate(nextKstMidnight), "己未");
});
