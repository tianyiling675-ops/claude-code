import { z } from 'zod';

// 服务端防护性硬顶：防止意外的 token 爆炸，不作为产品级字数提示
export const SummarizeRequestSchema = z.object({
  abstract: z
    .string()
    .trim()
    .min(10, '摘要内容过短')
    .max(20000, '摘要内容超出处理上限'),
});

export type SummarizeRequestInput = z.infer<typeof SummarizeRequestSchema>;
