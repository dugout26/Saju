// OpenAI 호출 헬퍼. 키는 Deno.env (Supabase secrets로 등록).

const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY")!;
const OPENAI_URL = "https://api.openai.com/v1/chat/completions";

export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

/// 단일 응답 (스트리밍 X). saju-reading, daily-oneliner에서 사용.
export async function chatCompletion(opts: {
  model: string;
  systemPrompt: string;
  userMessage: string;
  temperature?: number;
  maxTokens?: number;
}): Promise<string> {
  const res = await fetch(OPENAI_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: opts.model,
      messages: [
        { role: "system", content: opts.systemPrompt },
        { role: "user", content: opts.userMessage },
      ],
      temperature: opts.temperature ?? 0.7,
      max_tokens: opts.maxTokens ?? 800,
    }),
  });
  if (!res.ok) {
    throw new Error(`OpenAI ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  return data.choices[0].message.content as string;
}

/// SSE 스트리밍. chat에서 사용. OpenAI의 stream을 그대로 forward.
export async function chatCompletionStream(opts: {
  model: string;
  systemPrompt: string;
  messages: ChatMessage[];
}): Promise<ReadableStream<Uint8Array>> {
  const res = await fetch(OPENAI_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: opts.model,
      messages: [
        { role: "system", content: opts.systemPrompt },
        ...opts.messages,
      ],
      stream: true,
    }),
  });
  if (!res.ok || !res.body) {
    throw new Error(`OpenAI ${res.status}: ${await res.text()}`);
  }
  return res.body;
}
