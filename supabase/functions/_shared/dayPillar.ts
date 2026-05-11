// 일진(day pillar) 계산 — Manse.swift의 computeDayPillar/julianDayNumber 포팅.
// 클라이언트와 동일 알고리즘 (KST 자정 기준).
//
// Reference: JDN 2451545 (2000-01-01) = 戊午 (60갑자 index 54).
// 60갑자 index → 천간(10) × 지지(12) 매핑.

const STEMS = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];
const BRANCHES = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];

function julianDayNumber(year: number, month: number, day: number): number {
  let y = year;
  let m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  const a = Math.floor(y / 100);
  const b = 2 - a + Math.floor(a / 4);
  return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day + b - 1524;
}

/// 주어진 UTC Date의 KST 자정 기준 일진 문자열. 예: "庚午"
export function dayPillarOfDate(date: Date = new Date()): string {
  const kst = new Date(date.getTime() + 9 * 3600_000);
  const y = kst.getUTCFullYear();
  const m = kst.getUTCMonth() + 1;
  const d = kst.getUTCDate();
  const jdn = julianDayNumber(y, m, d);
  const referenceJDN = 2451545;
  const referenceIdx = 54;
  const idx60 = ((jdn - referenceJDN + referenceIdx) % 60 + 60) % 60;
  return STEMS[idx60 % 10] + BRANCHES[idx60 % 12];
}
