// trusted transaction state → DB action 결정 로직. index.ts의 serve() top-level
// 호출과 분리해 단위 테스트 가능. (test가 index.ts를 import하면 HTTP listener가
// 같이 부팅됨)

export type DBAction = "activate" | "cancel";

export interface TransactionState {
  revocationDate?: number;
  expiresDate?: number;
}

// revocationDate 있으면 환불/회수, expiresDate 지났거나 누락이면 cancel.
// auto-renewable subscription은 expiresDate 필수 — 누락은 비정상 상태로 간주.
export function deriveAction(tx: TransactionState): DBAction {
  if (tx.revocationDate) return "cancel";
  if (!tx.expiresDate) return "cancel";
  if (tx.expiresDate <= Date.now()) return "cancel";
  return "activate";
}
