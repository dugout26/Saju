// 사주 단계별 풀이 (1~5단계). 캐시 우선, 없으면 OpenAI 호출 후 saju_readings에 저장.
//
// 기획서 #6 평생 운세 18단계를 stage별로 분할:
//   stage 1: 글자판 + 음양오행 + 일간 기본 성향 (mini, 짧게)
//   stage 2: 사주 구조 + 강약 + 용신/희신/기신 + 성격·기질 (mini)
//   stage 3: 인간관계 + 가족운 + 연애/결혼운 (mini)
//   stage 4: 일/직업운 + 재물운 + 건강 (mini)
//   stage 5: 대운 흐름 + 향후 10년 + 시기별 조언 + 평생운 종합 (4o, 길게)
//
// POST /functions/v1/saju-reading
// Authorization: Bearer <user JWT>
// body: { stage: 1 | 2 | 3 | 4 | 5 }
// response: { content: string }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { corsHeaders, jsonError } from "../_shared/cors.ts";
import { getSupabaseClient, getUserId } from "../_shared/auth.ts";
import {
  BASE_SYSTEM_PROMPT,
  buildSajuContextBlock,
  chatCompletion,
  type SajuContext,
} from "../_shared/openai.ts";

// prompt 또는 maxTokens 변경 시 이 값을 올리면 자동 cache invalidation.
// 옛 row는 prompt_version < 현재 PROMPT_VERSION → cache miss → 새 호출.
const PROMPT_VERSION = 2;

/**
 * HTTP handler — saju-reading endpoint.
 * 흐름: stage 검증 → 캐시 확인(prompt_version 일치) → 사주·사용자 조회 → OpenAI 호출 → 저장.
 * 캐시 hit 시 즉시 반환, miss 시 stage별 모델·max_tokens로 호출 후 saju_readings에 upsert.
 */
async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const { stage } = await req.json() as { stage: number };
    if (!Number.isInteger(stage) || stage < 1 || stage > 5) {
      return jsonError("Invalid stage (1~5)", 400);
    }

    const supabase = getSupabaseClient(req);
    const userId = await getUserId(supabase);

    // 1) 캐시 확인 — 현재 PROMPT_VERSION과 일치할 때만 hit
    const { data: cached, error: cachedError } = await supabase
      .from("saju_readings")
      .select("content, prompt_version")
      .eq("user_id", userId)
      .eq("stage", stage)
      .maybeSingle();

    if (cachedError) {
      console.error("[saju-reading] cache read error:", cachedError);
      return jsonError("풀이를 불러오는 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.", 500);
    }

    if (cached && cached.prompt_version === PROMPT_VERSION) {
      return new Response(JSON.stringify({ content: cached.content }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2) 사주 + 사용자 조회
    const { data: profile } = await supabase
      .from("saju_profiles")
      .select("year_pillar, month_pillar, day_pillar, hour_pillar, day_master, five_elements_dist, gender")
      .eq("user_id", userId)
      .single();

    if (!profile) return jsonError("Saju profile not found", 404);

    const { data: user } = await supabase
      .from("users")
      .select("nickname")
      .eq("id", userId)
      .single();

    const saju: SajuContext = {
      yearPillar: profile.year_pillar,
      monthPillar: profile.month_pillar,
      dayPillar: profile.day_pillar,
      hourPillar: profile.hour_pillar ?? undefined,
      dayMaster: profile.day_master,
      fiveElements: profile.five_elements_dist ?? {},
      gender: profile.gender === "male"
        ? "남"
        : profile.gender === "female"
          ? "여"
          : "(미상)",
      nickname: user?.nickname ?? undefined,
    };

    // 3) OpenAI 호출 — 평생운만 4o, 나머지 mini
    const isLifetimeStage = stage === 5;
    const model = isLifetimeStage ? "gpt-4o" : "gpt-4o-mini";
    const userMessage = buildUserMessage(stage, saju);
    const maxTokens = maxTokensForStage(stage);

    const content = await chatCompletion({
      model,
      systemPrompt: BASE_SYSTEM_PROMPT,
      userMessage,
      maxTokens,
    });

    // 4) 저장 (race 조건은 unique constraint로 막힘) — 현재 PROMPT_VERSION 함께 저장.
    //    저장 실패해도 사용자에겐 응답 반환 (재방문 시 다시 호출됨). 로깅만.
    const { error: upsertError } = await supabase.from("saju_readings").upsert({
      user_id: userId,
      stage,
      content,
      ai_model_used: model,
      prompt_version: PROMPT_VERSION,
    }, { onConflict: "user_id,stage" });

    if (upsertError) {
      console.error("[saju-reading] cache upsert error:", upsertError);
    }

    return new Response(JSON.stringify({ content }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[saju-reading] unexpected error:", e);
    return jsonError("풀이를 불러오는 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.", 500);
  }
}

serve(handler);

/**
 * 단계별 OpenAI max_tokens 매핑.
 * stage 5(평생운)는 8개 대운 + 시기별 N개 해 자세한 풀이 위해 12000.
 * stage 1~4는 mini라 토큰 비용 부담 적어 cap 풀어 깊이 끌어냄.
 */
function maxTokensForStage(stage: number): number {
  switch (stage) {
    case 1: return 1500;
    case 2: return 2500;
    case 3: return 2500;
    case 4: return 2500;
    case 5: return 12000;
    default: return 1500;
  }
}

/**
 * stage별 user message 조립: 사주 컨텍스트 prefix + 이번 단계 요청 사항.
 * 사주 컨텍스트는 같은 user의 여러 stage 호출에서 동일 → OpenAI prompt caching prefix로 작용.
 */
function buildUserMessage(stage: number, saju: SajuContext): string {
  const ctx = buildSajuContextBlock(saju);
  return ctx + sectionsForStage(stage);
}

/**
 * 자평명리 평생운 18단계를 5개 stage로 분할한 요청 섹션.
 * stage 1~4는 mini로 짧고 빠르게, stage 5는 4o로 자세히. 각 stage는 일상 예시·자연 비유 활용 명시.
 * stage 5의 "앞으로 10년 흐름"엔 현재 연도 기준 범위를 동적으로 주입(20XX 플레이스홀더 방지).
 */
function sectionsForStage(stage: number): string {
  const currentYear = new Date().getFullYear();
  const yearRangeEnd = currentYear + 6;
  switch (stage) {
    case 1:
      return `[이번 풀이 범위 — 1단계: 첫인상]
1. 사주 글자판 정리
   - 천간·지지 8글자 각각 무슨 뜻인지 (한자 + 한글 풀이 + 자연 비유)
   - 표 또는 정렬된 형태로
2. 음양오행 개수 분석
   - 천간/지지/합산 개수
   - 강한 오행 약한 오행 일상어로
3. 일간의 기본 성향
   - 한 줄 요약 → 자세한 풀이
   - 일상에서 드러나는 모습 3~5개 예시

각 항목 "한 줄 요약 → 자세한 설명 + 일상 예시" 형식.
자연 비유 활용 (예: 큰 나무, 흐르는 물 등).
충분히 자세하게 작성.`;

    case 2:
      return `[이번 풀이 범위 — 2단계: 구조와 성격]
4. 사주의 전체 구조와 격국
5. 일간의 강약 분석 (월령·통근·지장간 흐름은 결론만 일상어로 — 왜 강한지/약한지 자연 비유로)
6. 용신/희신/기신 판단
   - 용신(균형을 맞춰주는 핵심 기운) — 왜 이게 용신인지 흐름 설명
   - 희신(용신을 도와주는 좋은 기운)
   - 기신(과하면 균형을 깨는 부담 기운)
7. 성격과 기질
   - 강점 (구체적 일상 예시 5개+)
   - 약점 (구체적 일상 예시 5개+)
   - 인간관계에서 나타나는 모습

각 섹션 "한 줄 요약 → 자세한 설명 + 일상 예시" 형식.
자연 비유 활용. 충분히 자세하게.`;

    case 3:
      return `[이번 풀이 범위 — 3단계: 관계]
8. 인간관계 성향
   - 사람과 어울리는 패턴
   - 강점·약점 일상 예시 4~6개
9. 가족운
   - 부모·형제와의 관계 경향
   - 가까운 사람 다루는 방식
   - 정서적 거리 조절 포인트
10. 연애·결혼운
   - 끌리는 사람의 유형 (사주 글자 근거로)
   - 연애에서 나타나는 모습 5~7개
   - 장기 관계에서 조심할 점
   - 좋은 관계의 조건

각 섹션 "한 줄 요약 → 자세한 풀이 + 일상 예시" 형식.
단정·예언 금지, 경향 중심. 충분히 자세하게.`;

    case 4:
      return `[이번 풀이 범위 — 4단계: 일·돈·건강]
11. 일/직업운
   - 잘 맞는 일의 방식 (분석/기획/표현 등)
   - 잘 맞는 업종·직무 6개+ (구체적으로)
   - 피하면 좋은 환경
   - 직장형/프리랜서/사업형 적합도
12. 돈/재물운
   - 사주에서 돈의 글자 위치와 의미
   - 돈을 버는 방식의 특징
   - 돈을 모으는 데 유리한/불리한 패턴
   - 충동소비·투자·계약·대출 조심할 점
   - 안정적 수입 구조 만드는 방향
13. 건강적으로 조심할 부분
   - 사주 오행에서 약한 부위/장기 경향 (의료 단정 금지, 생활 습관 차원)
   - 컨디션 관리 일상 팁

각 섹션 "한 줄 요약 → 자세한 설명 + 구체적 예시" 형식.
충분히 자세하게.`;

    case 5:
      return `[이번 풀이 범위 — 5단계: 평생운 종합]
지금까지 분석한 내용을 바탕으로 평생 흐름을 자세히 정리합니다.
이 단계는 PRO 사용자가 가장 비중 있게 보는 영역이므로 깊이 있게 작성하세요.

14. 대운(大運) 흐름
    - 8개 대운(약 80년)을 모두 표 형태로 정리:
      | 나이대 | 간지 | 핵심 의미 |
    - 현재 진입한 대운 자세히 풀이 (왜 중요, 좋은 흐름 5개+, 주의할 흐름 5개+)
    - 다음 대운 자세히 풀이 (어떻게 다른지, 무슨 변화가 오는지)

15. 앞으로 10년의 흐름
    - ${currentYear}년부터 ${yearRangeEnd}년까지 5~7개 해를 골라 연도별로:
      "예: ${currentYear}년 (간지) — 어떤 기운인지 → 좋은 활용법 / 조심할 점"
      "예: ${currentYear + 1}년 (간지) — ..."
    - 각 해마다 자세히 (200~400자씩). 반드시 실제 연도 명시 (플레이스홀더 X).

16. 조심해야 할 시기
    - 위 10년 안에서 특히 조심해야 할 해 2~3개
    - 왜 조심해야 하는지 사주 글자 작용으로 설명
    - 대처 방향

17. 잘 활용하면 좋은 시기
    - 위 10년 안에서 활용하기 좋은 해 2~3개
    - 어떤 영역에서 어떻게 쓰면 좋은지

18. 현실적인 조언
    - 생활 습관 / 마음가짐 / 인간관계 / 일하는 방식
    - 사주 균형을 맞추는 일상적 보완 (색·환경·습관 — 단정 X, 상징적 보완)

마지막에 "이 사주의 좋은 사용법" 정리 + 평생을 관통하는 격려 문단.

[형식] 각 섹션은 "한 줄 요약 → 자세한 설명 + 구체적 예시 + 자연 비유" 순서.
충분히 자세하게 풀어쓰기. 두루뭉술 금지.`;

    default:
      return "";
  }
}
