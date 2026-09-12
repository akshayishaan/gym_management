export type Backend = "next" | "nest";

export interface AuthSession {
  backend: Backend;
  gymId: string | null;
  setGymScope(gymId: string): void;
  request(
    method: string,
    path: string,
    opts?: { json?: unknown; form?: Record<string, string>; headers?: Record<string, string> },
  ): Promise<HttpResponse>;
}

export interface HttpResponse {
  status: number;
  headers: Record<string, string>;
  body: unknown; // parsed JSON, or raw string when not JSON
}

export interface TranscriptStep {
  step: string; // short stable name e.g. "members.list.active"
  method: string; // GET/POST/PUT/DELETE
  path: string; // path with ids already substituted (e.g. "/payments/67abc.../void")
  status: number;
  body: unknown;
  skipDiff?: boolean; // true for login/signup provisioning steps
}

export interface Transcript {
  backend: Backend;
  runId: string;
  steps: TranscriptStep[];
}
