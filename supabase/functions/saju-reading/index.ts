// 사주 단계별 풀이 (1~5단계). 캐시 우선, 없으면 OpenAI 호출 후 saju_readings에 저장.
//
// POST /functions/v1/saju-reading
// Authorization: Bearer <user JWT>
// body: { stage: 1 | 2 | 3 | 4 | 5 }
// response: { content: string }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { corsHeaders, jsonError } from "../_shared/cors.ts";
import { getSupabaseClient, getUserId } from "../_shared/auth.ts";
import { chatCompletion } from "../_shared/openai.ts";

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
      .select("year_pillar, month_pillar, day_pillar, hour_pillar, day_master, five_elements_dist")
      .eq("user_id", userId)
      .single();

    if (!profile) return jsonError("Saju profile not found", 404);

    const { data: user } = await supabase
      .from("users")
      .select("nickname")
      .eq("id", userId)
      .single();
    const nickname = user?.nickname ?? "사용자";

    // 3) OpenAI 호출 — 단계별 모델 차등
    const model = stage <= 2 ? "gpt-4o-mini" : "gpt-4o";
    const systemPrompt = buildSystemPrompt(stage);
    const userMessage = buildUserMessage(profile, nickname);
    const maxTokens = stage <= 2 ? 400 : (stage <= 4 ? 2500 : 4500);

    const content = await chatCompletion({ model, systemPrompt, userMessage, maxTokens });

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

function buildSystemPrompt(stage: number): string {
  return `당신은 자평명리(子平命理) 정통 방식의 사주 풀이 전문가입니다.

[중요 지시사항]
- 오직 사용자가 제공한 사주 정보만으로 객관적으로 해석하세요.
- 사용자에 대해 이미 알고 있는 어떤 정보도 해석에 반영하지 마세요.

[설명 방식 - 매우 중요]
- 독자는 사주 용어를 거의 모르는 초보자입니다.
- 천간, 지지, 일간, 십신, 격국, 용신, 대운 같은 용어가 처음 등장할 때 반드시 괄호로 쉬운 풀이를 붙이세요.
  예: "일간(태어난 날의 천간 = 나 자신을 나타내는 글자)"
  예: "용신(사주에서 균형을 맞춰주는 가장 중요한 기운)"
- 한자 용어는 반드시 한글 풀이를 함께 표기. 예: 戊(무, 큰 산의 기운)
- "비겁이 강하다" 같은 표현 대신 "나와 같은 편이 많아서 고집이 세다" 같은 일상 언어로 풀어주세요.
- 결론만 던지지 말고, "왜 그런지" 일상 비유나 예시로 설명하세요.
- 음양오행을 통해 화·수·목·금·토가 얼마나 있는지 분석.

[해석 프레임]
- 자평명리 정통 방식 (일간 중심, 강약·조후·통관·병약 용신).
- 일간 강약 판정 시 월령(월지의 계절 기운), 통근(천간이 같은 오행 지지에 뿌리), 지지장간(지지 안의 천간) 모두 고려하되, 그 과정의 결론만 쉬운 말로 전달하세요.
- 서양 점성술, 타로, MBTI 등 다른 체계와 섞지 마세요.
- 근거 없는 단정 대신 "이 글자가 이런 작용을 하니까 이런 경향이 나온다"는 흐름.

[금지]
- "절대", "100%", "반드시" 등 단정 표현
- 의료·질병·약물 단어
- 특정 종목·자산 추천
- 부정적 운명 단정
- 자해·자살 암시

[해석 순서 — ${stage}단계]
${sectionsForStage(stage)}

[형식 요청]
- 평문(plain text)만 사용. 마크다운(**굵게**, ##헤더, - 목록, *기울임* 등) 절대 금지.
- 강조가 필요하면 「」 같은 문장부호로.
- 1·2단계는 짧게(150~250자). 두루뭉술하지 않게 핵심만.
- 3·4단계는 중간 길이(500~700자), 5단계는 자세히(1500자+).
- 마지막에 가벼운 격려 한 줄.`;
}

function sectionsForStage(stage: number): string {
  switch (stage) {
    case 1: return `1. 내 사주 글자판 보여주기 (어떤 글자들로 구성되어 있는지, 그게 무슨 뜻인지)
2. 나라는 사람의 기본 성향 (일간 기준, 어떤 사람인지 한 줄로 요약 후 풀이)`;
    case 2: return `3. 성격과 기질 (강점, 약점, 사람들과의 관계에서 나타나는 모습)`;
    case 3: return `4. 일/돈 운의 큰 그림
5. 가족, 연애, 인간관계 경향`;
    case 4: return `6. 지금부터 10년간 어떤 흐름인지
7. 조심할 시기와 잘 활용하면 좋은 시기`;
    case 5: return `1. 내 사주 글자판
2. 기본 성향
3. 성격과 기질
4. 일/돈 운의 큰 그림
5. 가족, 연애, 인간관계 경향
6. 향후 10년 흐름
7. 조심할 시기와 잘 활용하면 좋은 시기 (평생운 종합)`;
    default: return "";
  }
}

function buildUserMessage(profile: any, nickname: string): string {
  return `[사주 원국 정보]
- 양력/음력: 양력 기준 변환됨
- 일간(태어난 날의 천간 = 나 자신): ${profile.day_master}
- 사주 4기둥 (시-일-월-년):
  - 시주: ${profile.hour_pillar ?? "미상 (출생 시간 모름)"}
  - 일주: ${profile.day_pillar}
  - 월주: ${profile.month_pillar}
  - 년주: ${profile.year_pillar}
- 오행 분포: ${formatElements(profile.five_elements_dist)}

${nickname}님을 위한 풀이를 작성하세요.`;
}

function formatElements(dist: Record<string, number>): string {
  const map: Record<string, string> = {
    "木": "목(나무)", "火": "화(불)", "土": "토(흙)", "金": "금(쇠)", "水": "수(물)"
  };
  return Object.entries(dist).map(([k, v]) => `${map[k] ?? k} ${v}개`).join(", ");
}
