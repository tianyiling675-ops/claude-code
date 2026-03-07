import SummaryPageClient from '@/components/SummaryPageClient';

export default function Home() {
  return (
    <main className="page">
      <header className="header">
        <svg
          className="header-icon"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20" />
          <path d="M8 7h6" />
          <path d="M8 11h8" />
        </svg>
        <h1>文献摘要工具</h1>
        <p>粘贴论文摘要，生成结构化的中文学术快报</p>
      </header>
      <SummaryPageClient />
    </main>
  );
}
