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
      style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}
    >
      <textarea
        value={abstract}
        onChange={(e) => onChange(e.target.value)}
        placeholder="请粘贴论文摘要..."
        rows={10}
        style={{
          width: '100%',
          padding: '12px',
          fontSize: '14px',
          lineHeight: '1.6',
          border: '1px solid #ccc',
          borderRadius: '6px',
          resize: 'vertical',
          fontFamily: 'inherit',
        }}
      />
      <button
        type="submit"
        disabled={isLoading || abstract.trim().length === 0}
        style={{
          padding: '10px 24px',
          fontSize: '15px',
          fontWeight: 600,
          color: '#fff',
          backgroundColor: isLoading ? '#999' : '#0070f3',
          border: 'none',
          borderRadius: '6px',
          cursor: isLoading ? 'not-allowed' : 'pointer',
          alignSelf: 'flex-start',
        }}
      >
        {isLoading ? '正在生成摘要...' : '生成结构化摘要'}
      </button>
    </form>
  );
}
