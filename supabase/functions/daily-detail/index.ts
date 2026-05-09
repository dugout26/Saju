// 자세한 일별 운세 — 사용자 기획서 #2 (오늘) / #3 (내일) 프롬프트 형식.
// 사용자가 "자세히 보기" 누를 때만 호출. 같은 user+date 캐시.
//
// POST /functions/v1/daily-detail
// Authorization: Bearer <user JWT>
// body: { day_pillar_of_date: string, for_date?: "YYYY-MM-DD", is_tomorrow?: boolean }
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

const PROMPT_VERSION = 1;

interface RequestBody {
  day_pillar_of_date: string;
  for_date?: string;
  is_tomorrow?: boolean;
}

/**
 * HTTP handler — daily-detail endpoint.
 * 흐름: 캐시 확인(prompt_version 일치) → 사주·사용자 조회 → OpenAI 호출 → 저장.
 */
async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const body = await req.json() as RequestBody;
    if (!body.day_pillar_of_date) return jsonError("day_pillar_of_date required", 400);

    const supabase = getSupabaseClient(req);
    const userId = await getUserId(supabase);
    const targetDate = body.for_date ?? new Date().toISOString().split("T")[0];

    // 1) 캐시 확인
    const { data: cached, error: cachedError } = await supabase
      .from("daily_detail_readings")
      .select("content, prompt_version")
      .eq("user_id", userId)
      .eq("date", targetDate)
      .maybeSingle();

    if (cachedError) {
      console.error("[daily-detail] cache read error:", cachedError);
      return jsonError("운세를 불러오는 중 오류가 발생했어요.", 500);
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
      gender: profile.gender === "male" ? "남"
        : profile.gender === "female" ? "여"
        : "(미상)",
      nickname: user?.nickname ?? undefined,
    };

    // 3) OpenAI 호출 — mini로 비용 절감 (자세하지만 일별이라 빈도 높을 수 있음)
    const userMessage = buildUserMessage(saju, body.day_pillar_of_date, targetDate, body.is_tomorrow ?? false);
    const content = await chatCompletion({
      model: "gpt-4o-mini",
      systemPrompt: BASE_SYSTEM_PROMPT,
      userMessage,
      maxTokens: 3000,
    });

    // 4) 저장
    const { error: upsertError } = await supabase.from("daily_detail_readings").upsert({
      user_id: userId,
      date: targetDate,
      content,
      prompt_version: PROMPT_VERSION,
      ai_model_used: "gpt-4o-mini",
    }, { onConflict: "user_id,date" });

    if (upsertError) {
      console.error("[daily-detail] cache upsert error:", upsertError);
    }

    return new Response(JSON.stringify({ content }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[daily-detail] unexpected error:", e);
    return jsonError("운세를 불러오는 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.", 500);
  }
}

/**
 * 사용자 #2(오늘) / #3(내일) 프롬프트 형식의 user message.
 * 캐시 hit를 위해 사주 컨텍스트를 prefix로.
 */
function buildUserMessage(saju: SajuContext, dayPillar: string, dateStr: string, isTomorrow: boolean): string {
  const ctx = buildSajuContextBlock(saju);
  const dayLabel = isTomorrow ? "내일" : "오늘";
  return ctx + `[${dayLabel} 일진]
- 날짜: ${dateStr}
- 일진 간지: ${dayPillar}

[이번 풀이 범위 — ${dayLabel}의 자세한 운세]
1. 일진의 간지·오행·일간 기준 십신 분석 (한 줄 + 풀이)
2. ${dayLabel}의 기운이 일간 ${saju.dayMaster}에게 주는 영향
3. 전체 흐름 (한 줄 요약 + 자세한 설명)
4. 일/공부/사업 운
5. 돈/소비/계약 운
6. 연애/인간관계 운
7. 컨디션/감정 흐름
8. ${dayLabel} 특히 조심할 점 (구체적 행동으로)
9. ${dayLabel} 잘 활용하면 좋은 행동 (구체적 행동으로)
10. ${dayLabel}의 키워드 3개

[설명 방식]
- 각 섹션 "한 줄 요약 → 자세한 설명 + 일상 예시" 순서.
- 사주 초보자도 이해할 수 있게 전문용어는 처음 등장 시 괄호로 풀이.
- 단정·예언 금지, 경향과 현실적 조언 중심.
- 자연 비유 활용.

[출력 형식]
# ${dayLabel} 운세 요약
한 줄 요약: ...

# ${dayLabel}의 일진 분석
- 간지 / 오행 / 일간에게 주는 영향

# 전체 흐름
# 일/공부/사업
# 돈/소비/계약
# 연애/인간관계
# 컨디션/감정
# 조심할 점
# 잘 활용하면 좋은 행동
# ${dayLabel}의 키워드 3개

[분량] 전체 1500~2000자. 충분히 자세하게.`;
}

serve(handler);
