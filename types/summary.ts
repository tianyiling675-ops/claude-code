export interface SummarizeRequest {
  abstract: string;
}

export interface SummarizeResponse {
  summary: string;
  requestId: string;
  elapsedMs: number;
}

export interface ApiErrorResponse {
  error: string;
  requestId: string;
}
