import type { AuthSession, Backend, HttpResponse } from "./types";

interface Cookie {
  name: string;
  value: string;
}

function splitCookie(setCookie: string): Cookie {
  // A set-cookie string is "name=value; Attr; Attr". Take up to the first ";"
  // so cookie values that themselves contain "=" are preserved intact.
  const firstSemi = setCookie.indexOf(";");
  const pair = firstSemi === -1 ? setCookie.trim() : setCookie.slice(0, firstSemi).trim();
  const eq = pair.indexOf("=");
  if (eq === -1) return { name: pair, value: "" };
  return { name: pair.slice(0, eq).trim(), value: pair.slice(eq + 1).trim() };
}

/**
 * Captures every cookie from a response, tolerating both the array form from
 * `Headers.getSetCookie()` (Node 18.14+) and the comma-joined `set-cookie` getter.
 */
function collectSetCookies(headers: Headers): Cookie[] {
  const getSetCookie = (
    headers as Headers & { getSetCookie?: () => string[] }
  ).getSetCookie;

  if (typeof getSetCookie === "function") {
    return getSetCookie.call(headers).map(splitCookie);
  }

  const combined = headers.get("set-cookie");
  if (!combined) return [];

  // Fallback: split on ", " only where an Expires/Max-Age attribute does not
  // precede the next cookie. Naive comma splitting breaks on `Expires` dates,
  // so join defensively around likely separators. In practice NextAuth emits
  // one cookie per header and getSetCookie() is available on Node 24.
  return combined
    .split(/,(?=\s*[^;,\s]+=)/)
    .map((raw) => splitCookie(raw.trim()));
}

function findCookie(cookies: Cookie[], name: string): string | null {
  const match = cookies.find((cookie) => cookie.name === name);
  return match ? match.value : null;
}

function headersToRecord(headers: Headers): Record<string, string> {
  const record: Record<string, string> = {};
  headers.forEach((value, key) => {
    record[key] = value;
  });
  return record;
}

export class NextAuthAdapter implements AuthSession {
  readonly backend: Backend = "next";
  gymId: string | null = null;

  private readonly base: string;
  private readonly sessionToken: string | null;
  private readonly csrfCookie: string | null;

  constructor(base: string, sessionToken: string | null = null, csrfCookie: string | null = null) {
    this.base = base.replace(/\/+$/, "");
    this.sessionToken = sessionToken;
    this.csrfCookie = csrfCookie;
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

    const cookieParts: string[] = [];
    if (this.sessionToken) cookieParts.push(`next-auth.session-token=${this.sessionToken}`);
    if (this.csrfCookie) cookieParts.push(`next-auth.csrf-token=${this.csrfCookie}`);
    if (this.gymId) cookieParts.push(`selectedGymId=${this.gymId}`);
    if (cookieParts.length > 0) headers.Cookie = cookieParts.join("; ");

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
  const response = await fetch(`${base}/api/auth/signup`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: adminName, email, password }),
  });

  if (response.status !== 201 && response.status !== 409) {
    throw new Error(`signup failed: ${response.status}`);
  }
}

async function establishSessionSessionToken(
  base: string,
  email: string,
  password: string,
): Promise<{ sessionToken: string; csrfCookie: string }> {
  // 1. Obtain a CSRF token and its (verbatim) cookie value.
  const csrfResponse = await fetch(`${base}/api/auth/csrf`);
  const csrfBody = (await csrfResponse.json()) as { csrfToken?: string };
  const csrfToken = csrfBody.csrfToken;
  if (!csrfToken) throw new Error("csrf token missing");

  const csrfCookie = findCookie(collectSetCookies(csrfResponse.headers), "next-auth.csrf-token");
  if (!csrfCookie) throw new Error("csrf cookie missing");

  // 2. Exchange credentials for a session token.
  const callbackResponse = await fetch(`${base}/api/auth/callback/credentials`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Cookie: `next-auth.csrf-token=${csrfCookie}`,
    },
    body: new URLSearchParams({
      csrfToken,
      email,
      password,
      callbackUrl: "http://localhost:3000",
      json: "true",
    }).toString(),
  });

  if (callbackResponse.status !== 200) {
    throw new Error(`callback/credentials failed: ${callbackResponse.status}`);
  }

  const sessionToken = findCookie(
    collectSetCookies(callbackResponse.headers),
    "next-auth.session-token",
  );
  if (!sessionToken) throw new Error("session token missing");

  return { sessionToken, csrfCookie };
}

export async function createNextAuthSession(
  base: string,
  email: string,
  password: string,
  adminName: string,
): Promise<AuthSession> {
  const normalizedBase = base.replace(/\/+$/, "");

  await signupAdmin(normalizedBase, adminName, email, password);
  const { sessionToken, csrfCookie } = await establishSessionSessionToken(
    normalizedBase,
    email,
    password,
  );

  return new NextAuthAdapter(normalizedBase, sessionToken, csrfCookie);
}
