// 매일 운세 전체 생성 (한 줄 + 색·방향·시간·숫자·피해야할것).
// 자평명리 일간 ↔ 일진 십신 관계와 충·형·합·회 작용으로 매일 다른 결과 생성.
//
// POST /functions/v1/daily-fortune
// 두 가지 호출 모드:
//   1. user JWT — body: { day_pillar_of_date, for_date? }. 클라이언트 흐름.
//   2. service_role JWT — body: { day_pillar_of_date, for_date?, user_id }. cron pregenerate 흐름.
// response: DailyFortuneDTO

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonError } from "../_shared/cors.ts";
import { getSupabaseClient, getUserId } from "../_shared/auth.ts";

const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY")!;

interface RequestBody {
  day_pillar_of_date: string;
  for_date?: string;   // "YYYY-MM-DD" — 미지정이면 오늘
  user_id?: string;    // service_role 호출 시 필수
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const body = await req.json() as RequestBody;
    if (!body.day_pillar_of_date) return jsonError("day_pillar_of_date required", 400);

    // 인증 분기 — service_role이면 user_id 받음, 일반 user JWT는 getUserId.
    // JWT decode로 role 확인은 payload 위조 가능 (signature 미검증). 따라서
    // service_role은 SUPABASE_SERVICE_ROLE_KEY와 직접 비교.
    const auth = req.headers.get("Authorization") ?? "";
    const token = auth.replace(/^Bearer\s+/i, "").trim();
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const isServiceRole = serviceRoleKey.length > 0 && token === serviceRoleKey;

    let userId: string;
    let supabase;
    if (isServiceRole) {
      if (!body.user_id) return jsonError("user_id required for service_role", 400);
      userId = body.user_id;
      supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      );
    } else {
      supabase = getSupabaseClient(req);
      userId = await getUserId(supabase);
    }
    const targetDate = body.for_date ?? new Date().toISOString().split("T")[0];

    // 1) 캐시 확인
    const { data: cached } = await supabase
      .from("daily_fortunes")
      .select("*")
      .eq("user_id", userId)
      .eq("date", targetDate)
      .maybeSingle();
    if (cached) {
      return new Response(JSON.stringify(cached), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2) 사주 + 닉네임
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

    // 2-b) 최근 7일 lucky_color_name history — LLM 색 다양성 강제용.
    //      날짜 BETWEEN today-7 AND today-1 (오늘 row는 아직 없음 = 캐시 miss path).
    const targetDateObj = new Date(`${targetDate}T00:00:00Z`);
    const weekAgo = new Date(targetDateObj.getTime() - 7 * 86400_000);
    const weekAgoStr = weekAgo.toISOString().split("T")[0];
    const yesterdayObj = new Date(targetDateObj.getTime() - 86400_000);
    const yesterdayStr = yesterdayObj.toISOString().split("T")[0];
    const { data: recentRows } = await supabase
      .from("daily_fortunes")
      .select("lucky_color_secondary")
      .eq("user_id", userId)
      .gte("date", weekAgoStr)
      .lte("date", yesterdayStr);
    const recentColors = (recentRows ?? [])
      .map((r: { lucky_color_secondary: string | null }) => r.lucky_color_secondary)
      .filter((c): c is string => !!c);

    // 3) OpenAI JSON mode
    const ai = await callOpenAI(profile, body.day_pillar_of_date, nickname, recentColors);

    // 4) DB upsert
    const row = {
      user_id: userId,
      date: targetDate,
      day_pillar_of_date: body.day_pillar_of_date,
      one_liner: ai.one_liner,
      lucky_color_primary: ai.lucky_color_hex,
      lucky_color_secondary: ai.lucky_color_name,
      lucky_direction: ai.lucky_direction,
      lucky_time_start: `${String(ai.lucky_time_start_hour).padStart(2, "0")}:00:00`,
      lucky_time_end:   `${String(ai.lucky_time_end_hour).padStart(2, "0")}:00:00`,
      lucky_numbers: ai.lucky_numbers,
      avoid: ai.avoid,
      ai_model_used: "gpt-4o-mini",
    };
    await supabase.from("daily_fortunes").upsert(row, { onConflict: "user_id,date" });

    // 클라이언트 응답에는 추가 필드 포함
    const response = {
      ...row,
      lucky_color_name: ai.lucky_color_name,
      lucky_color_theme: ai.lucky_color_theme,
      lucky_time_label: ai.lucky_time_label,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return jsonError((e as Error).message, 500);
  }
});

interface AIResponse {
  one_liner: string;
  lucky_color_name: string;
  lucky_color_hex: string;
  lucky_color_theme: "lavender" | "peach" | "mint" | "cream";
  lucky_direction: "동쪽" | "서쪽" | "남쪽" | "북쪽" | "중앙";
  lucky_time_start_hour: number;
  lucky_time_end_hour: number;
  lucky_time_label: string;
  lucky_numbers: number[];
  avoid: string;
}

async function callOpenAI(
  profile: any,
  dayPillar: string,
  nickname: string,
  recentColors: string[] = [],
): Promise<AIResponse> {
  const systemPrompt = `당신은 자평명리(子平命理) 정통 방식의 운세 해설가입니다.

[중요 지시사항]
- 오직 제공된 사주와 오늘의 일진(日辰)만으로 해석합니다.
- 사용자에 대한 외부 정보는 일절 사용 금지.

[분석 방식]
1. 일간(태어난 날의 천간 = 나)과 오늘 일진 천간의 십신 관계를 본다 (비겁/식상/재성/관성/인성).
2. 일진 지지가 사주 4기둥 지지와 충(沖)/형(刑)/합(合)/회(會) 작용이 있는지 본다.
3. 위 분석으로 오늘의 luckyElement(보충하면 좋은 오행)를 정한다.
4. luckyElement에 어울리는 색을 표준 5색에만 갇히지 말고 다양한 톤으로 제시.

[색 다양성 — 매우 중요]
- 木(나무) 계열: 민트, 세이지, 모스 그린, 올리브, 에메랄드, 라임, 포레스트, 청록 등
- 火(불) 계열: 코랄, 피치, 살구, 적벽돌, 핑크, 마젠타, 토마토, 와인 등
- 土(흙) 계열: 베이지, 크림, 모카, 카멜, 머스타드, 황토, 초콜릿, 샌드 등
- 金(쇠) 계열: 라벤더, 모브, 실버, 펄, 화이트, 아이보리, 그레이, 플래티넘 등
- 水(물) 계열: 인디고, 네이비, 미드나잇 블루, 코발트, 사파이어, 블랙, 다크 차콜 등
- 같은 사용자라도 매일 일진이 달라지므로 매일 다른 색을 제시할 것.

[lucky_color_theme — 디자인 시스템 매핑]
앱 UI는 4가지 톤만 지원: lavender(보라/회색/검정/네이비 차가운 톤), peach(주황/빨강/핑크 따뜻한 톤), mint(초록/청록/올리브), cream(노랑/베이지/갈색).
lucky_color_name이 어느 톤에 가장 가까운지 lucky_color_theme에 표기.

[방향]
木→동쪽, 火→남쪽, 土→중앙, 金→서쪽, 水→북쪽 (오늘의 luckyElement 기준).

[시간대 - 12지]
子(23-01) 丑(01-03) 寅(03-05) 卯(05-07) 辰(07-09) 巳(09-11) 午(11-13) 未(13-15) 申(15-17) 酉(17-19) 戌(19-21) 亥(21-23).
일진 + 사주에서 가장 도움이 되는 시간대를 1개 골라 시간 정수와 라벨(예: "申時 · 신시 (15-17시)").

[행운 숫자 - 河圖]
水 1·6, 火 2·7, 木 3·8, 金 4·9, 土 5·10. luckyElement 기준 1~3개.

[피해야 할 것]
일진과 사주의 충/형 작용에서 도출. 구체적 행동으로 (예: "충동적인 금전 결정", "감정적인 메시지 보내기").

[한 줄 운세]
40~70자. 사주 용어 풀어쓰기. 친근한 한국어. "~할 거예요", "~해보세요" 어조.

[금지]
"절대"·"100%"·"반드시" 등 단정 표현, 의료·종목·자해 단어, 부정적 운명 단정.

[출력 — JSON만, 다른 설명 X]
{
  "one_liner": "한 줄 운세",
  "lucky_color_name": "구체적 색 이름 (한국어)",
  "lucky_color_hex": "#XXXXXX",
  "lucky_color_theme": "lavender|peach|mint|cream",
  "lucky_direction": "동쪽|서쪽|남쪽|북쪽|중앙",
  "lucky_time_start_hour": 정수,
  "lucky_time_end_hour": 정수,
  "lucky_time_label": "申時 · 신시 (15-17시)",
  "lucky_numbers": [정수, ...],
  "avoid": "구체적 행동 한 줄"
}`;

  const recentColorsLine = recentColors.length > 0
    ? `\n[최근 7일 사용된 색 — 반드시 이 색들과 다른 색 제시]\n${recentColors.join(", ")}\n`
    : "";

  const userMessage = `[사주 원국]
- 일간: ${profile.day_master}
- 시주: ${profile.hour_pillar ?? "미상"}
- 일주: ${profile.day_pillar}
- 월주: ${profile.month_pillar}
- 년주: ${profile.year_pillar}
- 오행 분포: ${JSON.stringify(profile.five_elements_dist)}

[오늘의 일진]
${dayPillar}
${recentColorsLine}
${nickname}님의 오늘 운세를 위 JSON 형식으로 출력하세요.`;

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userMessage },
      ],
      response_format: { type: "json_object" },
      temperature: 0.85,
      max_tokens: 600,
    }),
  });
  if (!res.ok) throw new Error(`OpenAI ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const content = data.choices[0].message.content as string;
  return JSON.parse(content) as AIResponse;
}
