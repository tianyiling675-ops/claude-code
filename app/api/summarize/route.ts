// 显式声明 Node.js Runtime，避免部署到 Edge 时出现 OpenAI SDK 兼容问题
export const runtime = 'nodejs';
// 禁用路由级缓存，确保每次请求都真实执行
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { SummarizeRequestSchema } from '@/lib/validation';
import { generateSummary } from '@/lib/openai';
import type { SummarizeResponse, ApiErrorResponse } from '@/types/summary';

export async function POST(request: NextRequest): Promise<NextResponse<SummarizeResponse | ApiErrorResponse>> {
  const requestId = crypto.randomUUID();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: '请求体解析失败', requestId }, { status: 400 });
  }

  const parsed = SummarizeRequestSchema.safeParse(body);
  if (!parsed.success) {
    const firstError = parsed.error.errors[0];
    const isOverLimit = firstError?.code === 'too_big';
    const status = isOverLimit ? 413 : 400;
    return NextResponse.json(
      { error: firstError?.message ?? '输入校验失败', requestId },
      { status },
    );
  }

  const t0 = Date.now();
  try {
    const { summary, openaiRequestId } = await generateSummary(parsed.data.abstract);
    const elapsedMs = Date.now() - t0;

    console.log(JSON.stringify({ requestId, openaiRequestId, elapsedMs }));

    return NextResponse.json({ summary, requestId, elapsedMs });
  } catch (err) {
    const elapsedMs = Date.now() - t0;
    console.error(JSON.stringify({
      requestId,
      elapsedMs,
      error: err instanceof Error ? err.message : String(err),
    }));

    return NextResponse.json(
      { error: 'Internal Server Error', requestId },
      { status: 500 },
    );
  }
}
