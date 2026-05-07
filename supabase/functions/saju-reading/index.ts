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
    const maxTokens = stage <= 2 ? 600 : (stage <= 4 ? 1500 : 3000);

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
  const lengthGuide = stage <= 2
    ? "200~400자"
    : stage <= 4 ? "600~800자" : "1500자 내외";

  return `당신은 전통 명리학 기반의 운세 해설가입니다.
독자는 사주 용어를 모르는 20~30대 여성입니다.

[톤]
- "~합니다(확정)" 어조 금지. "~로 해석됩니다", "~한 흐름입니다" 사용
- 친근하고 부드러운 한국어

[금지]
- 의료·질병·약물 단어 (암, 우울증, 약 복용 등)
- 특정 종목·자산 추천
- 부정적 운명 단정
- "절대", "100%", "반드시" 등 단정 표현
- 자해·자살 암시

[권장]
- 사주 8글자 근거를 두고 설명
- 일상 비유 사용
- 마지막에 가벼운 격려 한 줄

[길이] ${stage}단계 풀이: ${lengthGuide}`;
}

function buildUserMessage(profile: any, nickname: string): string {
  return `사용자 사주:
- 시: ${profile.hour_pillar ?? "미상"}
- 일: ${profile.day_pillar}
- 월: ${profile.month_pillar}
- 년: ${profile.year_pillar}
- 일간: ${profile.day_master}
- 오행 분포: ${JSON.stringify(profile.five_elements_dist)}

${nickname}님을 위한 풀이를 작성하세요.`;
}
