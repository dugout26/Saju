// AI 챗봇 (유료 전용). OpenAI streaming을 SSE로 forward.
//
// POST /functions/v1/chat
// Authorization: Bearer <user JWT>
// body: { messages: [{ role: "user" | "assistant", content: string }, ...] }
// response: text/event-stream (OpenAI 형식 그대로)

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { corsHeaders, jsonError } from "../_shared/cors.ts";
import { getSupabaseClient, getUserId } from "../_shared/auth.ts";
import { chatCompletionStream, ChatMessage } from "../_shared/openai.ts";

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

    // 구독 확인
    const { data: user } = await supabase
      .from("users")
      .select("subscription_status")
      .eq("id", userId)
      .single();
    if (!user || (user.subscription_status !== "trial" && user.subscription_status !== "premium")) {
      return jsonError("유료 회원 전용입니다", 403);
    }

    // 사주 조회
    const { data: profile } = await supabase
      .from("saju_profiles")
      .select("year_pillar, month_pillar, day_pillar, hour_pillar, day_master")
      .eq("user_id", userId)
      .single();
    if (!profile) return jsonError("Saju profile not found", 404);

    const systemPrompt = `당신은 전통 명리학 기반의 운세 해설가입니다.
사용자는 무료체험 또는 프리미엄 회원입니다.

사용자 사주:
- 일간: ${profile.day_master}
- 사주 8자: ${profile.year_pillar} ${profile.month_pillar} ${profile.day_pillar} ${profile.hour_pillar ?? "(시간 미상)"}

규칙 (절대 어기지 마세요):
- "~합니다(확정)" 금지. "~로 해석됩니다", "~한 흐름입니다" 사용
- 의료·질병·약물 관련 단어 금지
- 특정 종목·자산 추천 금지
- "절대", "100%" 등 단정 표현 금지
- 부정적 운명 단정 금지
- 마지막에 가벼운 격려 한 줄

답변 길이: 4~7문장`;

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
      messages,
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
