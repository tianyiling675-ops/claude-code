Search for AI hackathons and AI-related competitions happening in the user's city.

## Instructions

The user may pass a city name as an argument: `$ARGUMENTS`

If `$ARGUMENTS` is empty, ask the user: "请问您在哪个城市？(e.g. 上海、北京、深圳、杭州, or an English city name)"

Once the city is known, perform **three parallel web searches**:

1. `AI hackathon 2025 2026 <city>` — look for upcoming AI hackathon events
2. `AI competition challenge 2025 2026 <city>` — broader AI competitions, model challenges, agent competitions
3. `人工智能 黑客松 比赛 2025 2026 <city>` — Chinese-language sources for the same

Also search globally for major online/remote AI competitions the user can join from anywhere:
4. `AI hackathon online remote 2025 2026`

## Output format

Present findings in a clean Markdown table or list grouped by:

### 🏙️ [City] 本地赛事
| 赛事名称 | 日期 | 地点 | 报名链接 | 备注 |
|---------|------|------|---------|------|

### 🌐 线上 / 全国性 AI 赛事
| 赛事名称 | 日期 | 形式 | 链接 | 备注 |
|---------|------|------|------|------|

For each event include:
- Event name (in original language + Chinese if available)
- Date / deadline
- Format (on-site / online / hybrid)
- Registration or info link
- Brief description (prize pool, theme, organizer)

If no local events are found, say so clearly and suggest the nearest major city or online alternatives.

End with a tip: "💡 建议同时关注 Devpost (devpost.com)、Kaggle (kaggle.com/competitions)、阿里天池、华为云大赛等平台获取最新赛事信息。"
