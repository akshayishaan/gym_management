import type { AuthSession, Backend, HttpResponse } from "./types";

function headersToRecord(headers: Headers): Record<string, string> {
  const record: Record<string, string> = {};
  headers.forEach((value, key) => {
    record[key] = value;
  });
  return record;
}

export class NestAuthAdapter implements AuthSession {
  readonly backend: Backend = "nest";
  gymId: string | null = null;

  private readonly base: string;
  private readonly accessToken: string | null;

  constructor(base: string, accessToken: string | null = null) {
    this.base = base.replace(/\/+$/, "");
    this.accessToken = accessToken;
  }

  setGymScope(gymId: string): void {
    this.gymId = gymId;
  }

  async request(
    method: string,
    path: string,
    opts?: { json?: unknown; form?: Record<string, string>; headers?: Record<string, string> },
  ): Promise<HttpResponse> {
    const headers: Record<string, string> = { ...opts?.headers };

    if (this.accessToken) headers.Authorization = `Bearer ${this.accessToken}`;
    if (this.gymId) headers["X-Selected-Gym"] = this.gymId;

    let body: string | undefined;
    if (opts?.json !== undefined) {
      headers["Content-Type"] = "application/json";
      body = JSON.stringify(opts.json);
    } else if (opts?.form) {
      headers["Content-Type"] = "application/x-www-form-urlencoded";
      body = new URLSearchParams(opts.form).toString();
    }

    const response = await fetch(`${this.base}${path}`, { method, headers, body });
    return toHttpResponse(response);
  }
}

async function toHttpResponse(response: Response): Promise<HttpResponse> {
  const raw = await response.text();
  let body: unknown = raw;
  if (raw) {
    try {
      body = JSON.parse(raw);
    } catch {
      // Raw text is a valid body — keep it.
    }
  }
  return { status: response.status, headers: headersToRecord(response.headers), body };
}

async function signupAdmin(base: string, adminName: string, email: string, password: string): Promise<void> {
  const response = await fetch(`${base}/auth/signup`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: adminName, email, password }),
  });

  if (response.status !== 201 && response.status !== 409) {
    throw new Error(`signup failed: ${response.status}`);
  }
}

async function login(base: string, email: string, password: string): Promise<string> {
  const response = await fetch(`${base}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });

  if (response.status !== 200) {
    throw new Error(`login failed: ${response.status}`);
  }

  const body = (await response.json()) as { accessToken?: string };
  if (!body.accessToken) throw new Error("access token missing");
  return body.accessToken;
}

export async function createNestAuthSession(
  base: string,
  email: string,
  password: string,
  adminName: string,
): Promise<AuthSession> {
  const normalizedBase = base.replace(/\/+$/, "");

  await signupAdmin(normalizedBase, adminName, email, password);
  const accessToken = await login(normalizedBase, email, password);

  return new NestAuthAdapter(normalizedBase, accessToken);
}
