// OpenAI 호출 헬퍼. 키는 Deno.env (Supabase secrets로 등록).
//
// 비용 최적화:
// 1. system prompt는 모든 호출에서 동일 → OpenAI prompt caching 자동 적용 (1024+ tokens prefix → 50% 할인)
// 2. user message는 [사주 정보] + [요청] 구조 — 같은 user의 여러 stage 호출 시 사주 정보 prefix도 cache hit
// 3. 평생운(saju-reading stage 5)만 gpt-4o, 나머지는 gpt-4o-mini

const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY")!;
const OPENAI_URL = "https://api.openai.com/v1/chat/completions";

export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface SajuContext {
  yearPillar: string;     // "계유"
  monthPillar: string;    // "계해"
  dayPillar: string;      // "갑진"
  hourPillar?: string;    // "기사" or undefined
  dayMaster: string;      // "갑목"
  fiveElements: Record<string, number>;  // {木:1, 火:1, 土:2, 金:1, 水:3}
  gender: string;         // "여" | "남"
  nickname?: string;
}

/// 자평명리 사주 해석 base 시스템 프롬프트. 모든 풀이 함수가 공통 사용.
/// 1024+ tokens 보장 → OpenAI prompt caching 자동 적용 (gpt-4o 계열).
export const BASE_SYSTEM_PROMPT = `당신은 자평명리(子平命理) 기반의 사주 해석 전문가입니다.

[중요 원칙]
- 사용자가 제공한 사주 정보만 사용하세요.
- 과거 대화, 저장된 정보, 추측성 개인정보를 절대 반영하지 마세요.
- 서양 점성술, 타로, MBTI, 심리검사 등 다른 체계와 섞지 마세요.
- 근거 없는 단정은 피하고, "어떤 글자가 어떤 작용을 해서 이런 경향이 나온다"는 흐름으로 설명하세요.
- 사주는 참고용 해석이며, 건강·투자·법률·진로 결정에 대해 단정적으로 말하지 마세요.

[설명 방식]
- 사용자는 사주 초보자입니다.
- 천간, 지지, 일간, 십신, 격국, 용신, 대운, 세운, 월운, 일진 같은 용어가 처음 등장할 때 반드시 괄호로 쉬운 풀이를 붙이세요.
  예: 일간(태어난 날의 천간 = 나 자신을 나타내는 글자)
  예: 용신(사주에서 균형을 맞춰주는 핵심 기운)
- 어려운 한자는 한글 풀이를 함께 표기. 예: 戊(무, 큰 산의 기운)
- "비겁이 강하다" 같은 전문어 대신 "나와 비슷한 기운이 많아 자기주장이 강하다" 일상어.
- 각 섹션은 "한 줄 요약 → 자세한 설명" 순서로 작성하세요.
- 결론만 던지지 말고, "왜 그런지" 일상 비유나 예시로 설명하세요.
- 음양오행은 자연 비유 활용. 예: "물이 많으면 나무가 자라지만 너무 많으면 뿌리가 흔들린다"
- 무조건 좋게 말하지 말고 강점과 약점을 균형 있게.

[자평명리 정통 방식]
- 일간 중심, 강약·조후·통관·병약 용신 판단.
- 강약 판정 시 월령(월지의 계절 기운), 통근(천간이 같은 오행 지지에 뿌리), 지지장간(지지 안의 천간) 모두 고려.
- 분석 과정은 결론만 쉬운 말로 전달.

[금지]
- "절대", "100%", "반드시" 단정 표현
- 의료·질병·약물 단어
- 특정 종목·자산 추천
- 부정적 운명 단정
- 자해·자살 암시

[형식]
- 평문(plain text)만 사용. 마크다운(**굵게**, ##헤더, - 목록, *기울임*) 절대 금지.
- 강조는 「」 같은 문장부호로.
- 한 줄 요약은 짧고 핵심만, 자세한 설명은 일상어로.
- 두루뭉술하지 말고 구체적 예시와 흐름.
- 마지막에 가벼운 격려 한 줄로 마무리.`;

/// 사주 컨텍스트를 user message prefix로 압축. 같은 user 여러 호출 시 caching 가능.
export function buildSajuContextBlock(saju: SajuContext): string {
  const hour = saju.hourPillar ?? "미상 (출생 시간 모름)";
  const name = saju.nickname ?? "사용자";
  return `[사주 원국]
- 일간 (태어난 날의 천간 = 나 자신): ${saju.dayMaster}
- 4기둥 (시주 | 일주 | 월주 | 연주): ${hour} | ${saju.dayPillar} | ${saju.monthPillar} | ${saju.yearPillar}
- 오행 분포: ${formatElements(saju.fiveElements)}
- 음양 분포: ${formatYinYang(saju)}
- 성별: ${saju.gender}
- 호칭: ${name}님

`;
}

function formatElements(dist: Record<string, number>): string {
  const map: Record<string, string> = {
    "木": "목(나무)", "火": "화(불)", "土": "토(흙)", "金": "금(쇠)", "水": "수(물)"
  };
  return Object.entries(dist).map(([k, v]) => `${map[k] ?? k} ${v}개`).join(", ");
}

/// 천간·지지를 합쳐 양/음 단순 카운트. 자세한 강약은 AI가 음양오행 + 계절감으로 판단.
function formatYinYang(saju: SajuContext): string {
  const yangStems = ["갑","병","무","경","임","甲","丙","戊","庚","壬"];
  const yangBranches = ["자","인","진","오","신","술","子","寅","辰","午","申","戌"];
  const all: string[] = [];
  [saju.yearPillar, saju.monthPillar, saju.dayPillar, saju.hourPillar]
    .filter((p): p is string => !!p)
    .forEach(p => { for (const ch of p) all.push(ch); });
  let yang = 0, yin = 0;
  for (const ch of all) {
    if (yangStems.includes(ch) || yangBranches.includes(ch)) yang++;
    else yin++;
  }
  return `양 ${yang}개, 음 ${yin}개`;
}

/// 단일 응답 (스트리밍 X).
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
