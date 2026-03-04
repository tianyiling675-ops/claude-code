import SummaryPageClient from '@/components/SummaryPageClient';

export default function Home() {
  return (
    <main
      style={{
        maxWidth: '720px',
        margin: '0 auto',
        padding: '48px 24px',
      }}
    >
      <h1 style={{ fontSize: '24px', fontWeight: 700, marginBottom: '8px' }}>
        文献摘要工具
      </h1>
      <p style={{ color: '#666', marginBottom: '32px', lineHeight: '1.6' }}>
        粘贴论文摘要，生成结构化的中文学术快报。
      </p>
      <SummaryPageClient />
    </main>
  );
}
