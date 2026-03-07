import type { Metadata } from 'next';
import './globals.css';

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
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
