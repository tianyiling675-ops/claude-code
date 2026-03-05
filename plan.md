# Plan：将 OpenAI 替换为 OpenRouter

## 背景

OpenRouter 的 API 与 OpenAI SDK 完全兼容，只需要：
1. 换 `baseURL` 为 `https://openrouter.ai/api/v1`
2. 换 API Key 环境变量
3. 模型名称加上 `openai/` 前缀（OpenRouter 的命名规范）

## 改动清单（共 3 个文件，约 6 行改动）

### 1. `lib/openai.ts` — 两处改动

- 环境变量名 `OPENAI_API_KEY` → `OPENROUTER_API_KEY`
- 创建 client 时增加 `baseURL: 'https://openrouter.ai/api/v1'`

```typescript
// 改前
if (!process.env.OPENAI_API_KEY) {
  throw new Error('[lib/openai] Missing environment variable: OPENAI_API_KEY');
}
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// 改后
if (!process.env.OPENROUTER_API_KEY) {
  throw new Error('[lib/openai] Missing environment variable: OPENROUTER_API_KEY');
}
const client = new OpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
});
```

### 2. `lib/prompts.ts` — 模型名称改动

OpenRouter 要求模型名使用 `组织/模型名` 格式：

```typescript
// 改前
export const OPENAI_MODEL = 'gpt-4o-mini';

// 改后
export const OPENAI_MODEL = 'openai/gpt-4o-mini';
```

> 你也可以换成 OpenRouter 上的其他模型，比如 `anthropic/claude-3.5-sonnet`、`google/gemini-2.0-flash` 等。

### 3. `.env.example` — 环境变量模板

```
// 改前
OPENAI_API_KEY=your_openai_api_key_here

// 改后
OPENROUTER_API_KEY=your_openrouter_api_key_here
```

## 你需要做的

改完代码后，在 `.env.local` 中填入你的 OpenRouter Key：
```
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxx
```

OpenRouter 的 Key 在 https://openrouter.ai/settings/keys 生成。

## 不需要改动的部分

- `openai` npm 包 — 继续使用，OpenRouter 与其完全兼容
- 前端组件 — 完全不受影响
- API Route — 完全不受影响
- Zod 校验 — 完全不受影响
