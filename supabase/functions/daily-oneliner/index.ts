// 매일 한 줄 운세 생성 + daily_fortunes 캐싱.
// 클라이언트가 매일 첫 진입 시 호출. 색·방향·시간·숫자·피해야할것은 클라이언트(DailyFortuneEngine.swift)가
// 만세력으로 계산해서 전송. Edge Function은 한 줄 운세 LLM 호출만 담당.
//
// POST /functions/v1/daily-oneliner
// Authorization: Bearer <user JWT>
// body: {
//   day_pillar_of_date: string,         // 클라이언트가 계산한 오늘 일진
//   lucky_color_primary: string,        // hex
//   lucky_color_secondary?: string,
//   lucky_direction: string,            // "동쪽" | "서쪽" | "남쪽" | "북쪽" | "중앙"
//   lucky_time_start: string,           // "HH:MM" (24h)
//   lucky_time_end: string,
//   lucky_numbers: number[],
//   avoid: string,
// }
// response: 같은 row 전체 (DailyFortuneDTO와 매칭)

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { corsHeaders, jsonError } from "../_shared/cors.ts";
import { getSupabaseClient, getUserId } from "../_shared/auth.ts";
import { chatCompletion } from "../_shared/openai.ts";

interface RequestBody {
  day_pillar_of_date: string;
  lucky_color_primary: string;
  lucky_color_secondary?: string;
  lucky_direction: string;
  lucky_time_start: string;
  lucky_time_end: string;
  lucky_numbers: number[];
  avoid: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const body = await req.json() as RequestBody;
    const supabase = getSupabaseClient(req);
    const userId = await getUserId(supabase);

    const today = new Date().toISOString().split("T")[0];

    // 1) 오늘 캐시 확인
    const { data: cached } = await supabase
      .from("daily_fortunes")
      .select("*")
      .eq("user_id", userId)
      .eq("date", today)
      .maybeSingle();

    if (cached) {
      return new Response(JSON.stringify(cached), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2) 사주 조회
    const { data: profile } = await supabase
      .from("saju_profiles")
      .select("day_master")
      .eq("user_id", userId)
      .single();
    if (!profile) return jsonError("Saju profile not found", 404);

    const { data: user } = await supabase
      .from("users")
      .select("nickname")
      .eq("id", userId)
      .single();

    // 3) OpenAI: 한 줄 운세
    const systemPrompt = `당신은 전통 명리학 기반의 운세 해설가입니다.
다음 정보를 바탕으로 오늘 하루를 한 줄(40~60자)로 요약하세요.

규칙:
- "~할 거예요", "~해보세요" 어조
- 의료·질병·종목명·확정 표현 금지
- 마지막은 부드럽게

출력 형식: 한 줄 텍스트만. 따옴표·줄바꿈·이모지 없이.`;

    const userMessage = `사용자 사주: ${profile.day_master} 일간
오늘의 일진: ${body.day_pillar_of_date}
오늘의 행운 색: ${body.lucky_color_primary}
오늘의 행운 방향: ${body.lucky_direction}

${user?.nickname ?? "사용자"}님의 오늘을 한 줄로 표현해주세요.`;

    const oneLiner = await chatCompletion({
      model: "gpt-4o-mini",
      systemPrompt,
      userMessage,
      maxTokens: 120,
      temperature: 0.85,
    });

    // 4) upsert
    const fortune = {
      user_id: userId,
      date: today,
      day_pillar_of_date: body.day_pillar_of_date,
      one_liner: oneLiner.trim(),
      lucky_color_primary: body.lucky_color_primary,
      lucky_color_secondary: body.lucky_color_secondary ?? null,
      lucky_direction: body.lucky_direction,
      lucky_time_start: body.lucky_time_start,
      lucky_time_end: body.lucky_time_end,
      lucky_numbers: body.lucky_numbers,
      avoid: body.avoid,
      ai_model_used: "gpt-4o-mini",
    };
    await supabase.from("daily_fortunes").upsert(fortune, { onConflict: "user_id,date" });

    return new Response(JSON.stringify(fortune), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return jsonError((e as Error).message, 500);
  }
});
