import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: '文献摘要工具',
  description: '将论文摘要转化为结构化中文学术快报',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body style={{ margin: 0, fontFamily: 'system-ui, -apple-system, sans-serif' }}>
        {children}
      </body>
    </html>
  );
}
