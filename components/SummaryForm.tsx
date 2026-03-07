interface SummaryFormProps {
  abstract: string;
  onChange: (v: string) => void;
  onSubmit: () => void;
  isLoading: boolean;
}

export default function SummaryForm({ abstract, onChange, onSubmit, isLoading }: SummaryFormProps) {
  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        onSubmit();
      }}
      className="form"
    >
      <div className="textarea-wrapper">
        <textarea
          value={abstract}
          onChange={(e) => onChange(e.target.value)}
          placeholder="在此粘贴论文摘要..."
          rows={8}
          className="textarea"
        />
      </div>
      <button
        type="submit"
        disabled={isLoading || abstract.trim().length === 0}
        className="submit-button"
      >
        {isLoading ? (
          <>
            <span className="spinner" />
            处理中
          </>
        ) : (
          <>
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M5 12h14" />
              <path d="m12 5 7 7-7 7" />
            </svg>
            生成摘要
          </>
        )}
      </button>
    </form>
  );
}
