import OpenAI from 'openai';
import { SUMMARIZE_SYSTEM_PROMPT, OPENAI_MODEL, MAX_COMPLETION_TOKENS } from './prompts';

if (!process.env.OPENAI_API_KEY) {
  throw new Error('[lib/openai] Missing environment variable: OPENAI_API_KEY');
}

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export interface GenerateSummaryResult {
  summary: string;
  openaiRequestId: string | null;
}

export async function generateSummary(abstract: string): Promise<GenerateSummaryResult> {
  const completion = await client.chat.completions.create({
    model: OPENAI_MODEL,
    max_completion_tokens: MAX_COMPLETION_TOKENS,
    messages: [
      { role: 'system', content: SUMMARIZE_SYSTEM_PROMPT },
      { role: 'user', content: abstract },
    ],
  });

  const summary = completion.choices[0]?.message?.content;
  if (!summary) throw new Error('OpenAI returned empty response');

  // _request_id 是 SDK 内部字段，用于服务端日志与 OpenAI 问题定位
  const openaiRequestId = (completion as { _request_id?: string | null })._request_id ?? null;

  return { summary, openaiRequestId };
}
