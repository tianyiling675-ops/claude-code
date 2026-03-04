interface SummaryResultProps {
  summary: string;
  error: string;
}

export default function SummaryResult({ summary, error }: SummaryResultProps) {
  if (error) {
    return (
      <div
        style={{
          padding: '16px',
          backgroundColor: '#fef2f2',
          border: '1px solid #fca5a5',
          borderRadius: '6px',
          color: '#991b1b',
          lineHeight: '1.6',
        }}
      >
        {error}
      </div>
    );
  }

  if (summary) {
    return (
      <div
        style={{
          padding: '16px',
          backgroundColor: '#f0fdf4',
          border: '1px solid #86efac',
          borderRadius: '6px',
          whiteSpace: 'pre-wrap',
          lineHeight: '1.8',
          fontSize: '14px',
        }}
      >
        {summary}
      </div>
    );
  }

  return null;
}
