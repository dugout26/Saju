// AI 챗봇 (유료 전용). OpenAI streaming을 SSE로 forward.
//
// POST /functions/v1/chat
// Authorization: Bearer <user JWT>
// body: { messages: [{ role: "user" | "assistant", content: string }, ...] }
// response: text/event-stream (OpenAI 형식 그대로)

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { corsHeaders, jsonError } from "../_shared/cors.ts";
import { getSupabaseClient, getUserId } from "../_shared/auth.ts";
import {
  BASE_SYSTEM_PROMPT,
  buildSajuContextBlock,
  chatCompletionStream,
  type ChatMessage,
  type SajuContext,
} from "../_shared/openai.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  try {
    const { messages } = await req.json() as { messages: ChatMessage[] };
    if (!Array.isArray(messages) || messages.length === 0) {
      return jsonError("messages required", 400);
    }

    const supabase = getSupabaseClient(req);
    const userId = await getUserId(supabase);

    // 광고 모델: 무료 사용자도 호출 가능 (클라이언트가 광고 시청 후 1턴 호출).
    // 어뷰즈는 출시 후 데이터 보고 결정 (SSAI 토큰 검증 또는 daily counter 추가).

    // 사주 + 닉네임 조회 (chat 시스템 프롬프트와 user message context에 주입)
    const { data: profile } = await supabase
      .from("saju_profiles")
      .select("year_pillar, month_pillar, day_pillar, hour_pillar, day_master, five_elements_dist, gender")
      .eq("user_id", userId)
      .single();
    if (!profile) return jsonError("Saju profile not found", 404);

    const { data: userInfo } = await supabase
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
      nickname: userInfo?.nickname ?? undefined,
    };

    // 챗봇은 BASE 프롬프트 + 챗봇 전용 추가 가이드 (대화 톤, 길이)
    const systemPrompt = BASE_SYSTEM_PROMPT + `

[챗봇 전용 톤]
- 대화체로 친근하게.
- 답변은 4~7문장. 너무 길게 늘이지 마세요.
- 사용자 질문이 모호하면 한 번 되묻고 답변.
- 사용자 사주를 기반으로만 답변. 일반론은 피하기.`;

    // 사주 컨텍스트를 첫 user message로 주입 (caching 효과 + 매 호출 안 보내도 됨)
    const sajuContextMsg: ChatMessage = {
      role: "user",
      content: buildSajuContextBlock(saju) + "위 사주를 기반으로 아래 질문에 답해주세요.",
    };
    const sajuAckMsg: ChatMessage = {
      role: "assistant",
      content: "네, 사주 정보 확인했어요. 무엇이 궁금하신가요?",
    };
    const allMessages = [sajuContextMsg, sajuAckMsg, ...messages];

    // 사용자 메시지 저장 (마지막 user 메시지만)
    const lastUserMsg = [...messages].reverse().find((m) => m.role === "user");
    if (lastUserMsg) {
      await supabase.from("chat_messages").insert({
        user_id: userId,
        role: "user",
        content: lastUserMsg.content,
      });
    }

    // OpenAI streaming 시작
    const upstream = await chatCompletionStream({
      model: "gpt-4o-mini",
      systemPrompt,
      messages: allMessages,
    });

    // assistant 응답은 클라이언트에서 SwiftData 저장 (Phase B-2 simplicity)
    return new Response(upstream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    });
  } catch (e) {
    return jsonError((e as Error).message, 500);
  }
});
