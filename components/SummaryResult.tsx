interface SummaryResultProps {
  summary: string;
  error: string;
}

export default function SummaryResult({ summary, error }: SummaryResultProps) {
  if (error) {
    return (
      <div className="content-section">
        <div className="error">
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <span className="error-text">{error}</span>
        </div>
      </div>
    );
  }

  if (summary) {
    return (
      <div className="content-section">
        <div className="result">
          <div className="result-label">
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
              <polyline points="14 2 14 8 20 8" />
              <line x1="16" y1="13" x2="8" y2="13" />
              <line x1="16" y1="17" x2="8" y2="17" />
            </svg>
            Analysis
          </div>
          <div className="result-content">{summary}</div>
        </div>
      </div>
    );
  }

  return null;
}
