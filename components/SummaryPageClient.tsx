'use client';

import { useState } from 'react';
import SummaryForm from './SummaryForm';
import SummaryResult from './SummaryResult';
import type { SummarizeResponse, ApiErrorResponse } from '@/types/summary';

export default function SummaryPageClient() {
  const [abstract, setAbstract] = useState('');
  const [summary, setSummary] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit() {
    setIsLoading(true);
    setError('');
    setSummary('');

    try {
      const response = await fetch('/api/summarize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ abstract }),
      });

      const data: SummarizeResponse | ApiErrorResponse = await response.json();

      if (!response.ok) {
        setError((data as ApiErrorResponse).error);
      } else {
        setSummary((data as SummarizeResponse).summary);
      }
    } catch {
      setError('网络请求失败，请检查网络连接后重试');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <SummaryForm
        abstract={abstract}
        onChange={setAbstract}
        onSubmit={handleSubmit}
        isLoading={isLoading}
      />
      <SummaryResult summary={summary} error={error} />
    </div>
  );
}
