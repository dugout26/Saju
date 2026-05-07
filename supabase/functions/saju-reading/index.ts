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

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const { stage } = await req.json() as { stage: number };
    if (!Number.isInteger(stage) || stage < 1 || stage > 5) {
      return jsonError("Invalid stage (1~5)", 400);
    }

    const supabase = getSupabaseClient(req);
    const userId = await getUserId(supabase);

    // 1) 캐시 확인
    const { data: cached } = await supabase
      .from("saju_readings")
      .select("content")
      .eq("user_id", userId)
      .eq("stage", stage)
      .maybeSingle();

    if (cached) {
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
      gender: profile.gender === "male" ? "남" : "여",
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

    // 4) 저장 (race 조건은 unique constraint로 막힘)
    await supabase.from("saju_readings").upsert({
      user_id: userId,
      stage,
      content,
      ai_model_used: model,
    }, { onConflict: "user_id,stage" });

    return new Response(JSON.stringify({ content }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return jsonError((e as Error).message, 500);
  }
});

function maxTokensForStage(stage: number): number {
  switch (stage) {
    case 1: return 600;
    case 2: return 800;
    case 3: return 800;
    case 4: return 800;
    case 5: return 4000;
    default: return 600;
  }
}

function buildUserMessage(stage: number, saju: SajuContext): string {
  const ctx = buildSajuContextBlock(saju);
  return ctx + sectionsForStage(stage);
}

function sectionsForStage(stage: number): string {
  switch (stage) {
    case 1:
      return `[이번 풀이 범위 — 1단계: 첫인상]
1. 사주 글자판 정리 (어떤 글자들로 구성됐고 무슨 뜻인지 짧게)
2. 음양오행 개수 분석 (오행 강약 한 줄 요약)
3. 일간의 기본 성향 (한 줄 요약 + 일상어로 풀이)

[분량] 전체 200~300자. 짧고 핵심만.`;

    case 2:
      return `[이번 풀이 범위 — 2단계: 구조와 성격]
4. 사주의 전체 구조와 격국 (한 줄 + 풀이)
5. 일간의 강약 분석 (월령·통근·지장간 흐름은 결론만 일상어로)
6. 용신/희신/기신 판단
   - 용신(균형을 맞춰주는 핵심 기운)
   - 희신(용신을 도와주는 좋은 기운)
   - 기신(과하면 균형을 깨는 부담 기운)
7. 성격과 기질 (강점, 약점, 일상에서 드러나는 모습)

[분량] 전체 400~500자. 자연 비유 활용.`;

    case 3:
      return `[이번 풀이 범위 — 3단계: 관계]
8. 인간관계 성향 (사람들과 어울리는 패턴)
9. 가족운 (부모·형제 관계 경향)
10. 연애·결혼운 (만남의 패턴, 장기 관계에서의 모습)

각 섹션 "한 줄 요약 → 일상어 풀이". 단정·예언 금지, 경향 중심.

[분량] 전체 400~500자.`;

    case 4:
      return `[이번 풀이 범위 — 4단계: 일·돈·건강]
11. 일/직업운 (잘 맞는 일의 방식, 환경)
12. 돈/재물운 (돈을 버는 방식, 모으는 방식, 조심할 점)
13. 건강적으로 조심할 부분 (의료 단정 금지, 생활 습관 차원에서 경향만)

각 섹션 "한 줄 요약 → 자세한 설명".

[분량] 전체 400~500자.`;

    case 5:
      return `[이번 풀이 범위 — 5단계: 평생운 종합]
지금까지 분석한 내용을 바탕으로 평생 흐름을 정리합니다.

14. 대운 흐름 (10년 단위로 어떤 기운이 들어오는지)
15. 앞으로 10년의 흐름 (가장 가까운 대운 + 세운 변화)
16. 조심해야 할 시기 (특정 기간을 단정하지 말고 경향과 활용법으로)
17. 잘 활용하면 좋은 시기
18. 현실적인 조언 (생활 차원, 마음가짐)

마지막에 평생을 관통하는 한 줄 격려.

[분량] 전체 1500~2000자. 자세하게. 자연 비유 활용.
[형식] 각 섹션은 "한 줄 요약 → 자세한 설명" 순서.`;

    default:
      return "";
  }
}
