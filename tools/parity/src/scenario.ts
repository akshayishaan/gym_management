import { createRequestId } from "./uuid";
import { todayInGymTz } from "./displayStatus";
import type { AuthSession, TranscriptStep } from "./types";

export interface SeedIds {
  gymId: string;
  planIdA: string;
  planIdB: string;
  memberA: string;
  memberB: string;
  membershipIdB: string;
  paymentIdB: string;
  membershipIdZero: string;
  paymentIdDues: string;
  paymentIdPlan2: string;
  membershipIdPlan2: string;
  /** requestId of the step-8 payment, reused verbatim for `edge.idempotent`. */
  paymentPlan2RequestId: string;
}

const HEX24_RE = /^[0-9a-f]{24}$/i;
const ID_KEYS = ["_id", "id", "paymentId", "membershipId", "memberId"];

/** Next.js serves API routes under `/api`; Nest serves controllers at root. */
function apiPrefix(session: AuthSession): string {
  return session.backend === "next" ? "/api" : "";
}

function isHex24(value: unknown): value is string {
  return typeof value === "string" && HEX24_RE.test(value);
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== "object") return false;
  const proto = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === null;
}

function at(body: unknown, ...path: string[]): unknown {
  let current = body;
  for (const key of path) {
    if (!isPlainObject(current)) return undefined;
    current = current[key];
  }
  return current;
}

/** Recursively scans a response body for the first 24-hex id value. */
function findNestedHex(body: unknown): string | null {
  if (isHex24(body)) return body;
  if (Array.isArray(body)) {
    for (const item of body) {
      const found = findNestedHex(item);
      if (found) return found;
    }
    return null;
  }
  if (isPlainObject(body)) {
    for (const [key, value] of Object.entries(body)) {
      if (ID_KEYS.includes(key) && isHex24(value)) return value;
      const found = findNestedHex(value);
      if (found) return found;
    }
  }
  return null;
}

/**
 * Extracts a required 24-hex id from a response body, preferring exact known
 * locations and falling back to a recursive scan before failing loudly.
 */
function requireId(candidate: unknown, body: unknown, label: string): string {
  if (isHex24(candidate)) return candidate;
  const fallback = findNestedHex(body);
  if (fallback) return fallback;
  throw new Error(`seed: required id "${label}" missing from response`);
}

async function runStep(
  session: AuthSession,
  name: string,
  method: string,
  path: string,
  json?: unknown,
): Promise<TranscriptStep> {
  const response = await session.request(
    method,
    `${apiPrefix(session)}${path}`,
    json === undefined ? undefined : { json },
  );
  return { step: name, method, path, status: response.status, body: response.body };
}

/**
 * Runs the SEEDING mutations for THIS backend run, recording every persisted
 * id. Each run (next and nest) seeds its own fresh gym + plans + members under
 * a backend-distinct name, so the two runs isolate cleanly in the shared DB.
 * Each mutation carries a fresh `requestId`.
 */
export async function seed(runId: string, session: AuthSession): Promise<SeedIds> {
  const today = todayInGymTz();
  const prefix = apiPrefix(session);

  // Each backend run seeds its OWN admin (backend-distinct email) and thus its
  // own gym scope; the shared Atlas cluster is isolated by gym scoping, NOT by
  // name. Display names carry only the shared runId so that the next and nest
  // runs produce IDENTICAL names, which the diff compares literally.
  const suffix = runId;

  // 1. Create the tenant gym, then scope subsequent requests to it.
  let res = await session.request("POST", `${prefix}/gyms`, {
    json: { name: `Parity Gym ${suffix}`, timezone: "Asia/Kolkata", currency: "INR" },
  });
  const gymId = requireId(at(res.body, "_id") ?? at(res.body, "id"), res.body, "gymId");
  session.setGymScope(gymId);

  // 2. Plan A (Gold, 30 days).
  res = await session.request("POST", `${prefix}/plans`, {
    json: {
      name: `Gold ${suffix}`,
      durationDays: 30,
      price: 1000,
      features: ["Gym", " Pool", "gym", "Pool", ""],
    },
  });
  const planIdA = requireId(at(res.body, "_id") ?? at(res.body, "id"), res.body, "planIdA");

  // 3. Plan B (Basic, 7 days).
  res = await session.request("POST", `${prefix}/plans`, {
    json: { name: `Basic ${suffix}`, durationDays: 7, price: 300 },
  });
  const planIdB = requireId(at(res.body, "_id") ?? at(res.body, "id"), res.body, "planIdB");

  // 4. Member A — no plan.
  res = await session.request("POST", `${prefix}/members`, {
    json: { requestId: createRequestId(), name: `Member NoPlan ${suffix}`, phone: "1000000001" },
  });
  const memberA = requireId(at(res.body, "member", "_id") ?? at(res.body, "_id"), res.body, "memberA");

  // 5. Member B — onboarded with plan A and an initial payment.
  res = await session.request("POST", `${prefix}/members`, {
    json: {
      requestId: createRequestId(),
      name: `Member WithPlan ${suffix}`,
      phone: "1000000002",
      planId: planIdA,
      amountPaid: 1000,
      paymentMethod: "cash",
      membershipStart: today,
    },
  });
  const memberB = requireId(at(res.body, "member", "_id") ?? at(res.body, "_id"), res.body, "memberB");
  const membershipIdB = requireId(at(res.body, "membershipId"), res.body, "membershipIdB");
  const paymentIdB = requireId(at(res.body, "payment", "_id") ?? at(res.body, "paymentId"), res.body, "paymentIdB");

  // 6. Zero-amount plan payment → zero-valued membership.
  res = await session.request("POST", `${prefix}/payments`, {
    json: { requestId: createRequestId(), memberId: memberB, planId: planIdA, amount: 0, method: "cash" },
  });
  const membershipIdZero = requireId(at(res.body, "membershipId"), res.body, "membershipIdZero");

  // 7. Dues payment (no planId).
  res = await session.request("POST", `${prefix}/payments`, {
    json: { requestId: createRequestId(), memberId: memberB, amount: 500, method: "card" },
  });
  const paymentIdDues = requireId(at(res.body, "paymentId"), res.body, "paymentIdDues");

  // 8. Plan-B payment (its requestId is captured for the idempotency probe).
  const paymentPlan2RequestId = createRequestId();
  res = await session.request("POST", `${prefix}/payments`, {
    json: { requestId: paymentPlan2RequestId, memberId: memberB, planId: planIdB, amount: 300, method: "upi" },
  });
  const paymentIdPlan2 = requireId(at(res.body, "paymentId"), res.body, "paymentIdPlan2");
  const membershipIdPlan2 = requireId(at(res.body, "membershipId"), res.body, "membershipIdPlan2");

  return {
    gymId,
    planIdA,
    planIdB,
    memberA,
    memberB,
    membershipIdB,
    paymentIdB,
    membershipIdZero,
    paymentIdDues,
    paymentIdPlan2,
    membershipIdPlan2,
    paymentPlan2RequestId,
  };
}

/**
 * Runs the EDGE-CASE PROBES + READS for a given backend, producing diffable
 * transcript steps. Probes mutate; reads are stable and backend-independent.
 */
export async function probeAndRead(
  runId: string,
  session: AuthSession,
  ids: SeedIds,
): Promise<TranscriptStep[]> {
  const today = todayInGymTz();
  const currentMonth = today.slice(0, 7);
  const currentYear = today.slice(0, 4);

  const steps: TranscriptStep[] = [];
  const push = (step: TranscriptStep) => steps.push(step);

  // --- EDGE-CASE PROBES (fresh requestId unless replaying a captured one) ---

  push(await runStep(session, "edge.overlap", "POST", "/payments", {
    requestId: createRequestId(),
    memberId: ids.memberB,
    planId: ids.planIdA,
    amount: 1000,
    membershipStart: today,
  }));

  push(await runStep(session, "edge.dues.nonPositive", "POST", "/payments", {
    requestId: createRequestId(),
    memberId: ids.memberB,
    amount: 0,
  }));

  push(await runStep(session, "edge.dues.exceeds", "POST", "/payments", {
    requestId: createRequestId(),
    memberId: ids.memberA,
    amount: 99999,
  }));

  push(await runStep(session, "edge.idempotent", "POST", "/payments", {
    requestId: ids.paymentPlan2RequestId,
    memberId: ids.memberB,
    planId: ids.planIdB,
    amount: 300,
    method: "upi",
  }));

  push(await runStep(session, "edge.void", "POST", `/payments/${ids.paymentIdPlan2}/void`, {
    requestId: createRequestId(),
    reason: "parity test",
  }));

  push(await runStep(session, "edge.refund", "POST", `/payments/${ids.paymentIdB}/refund`, {
    requestId: createRequestId(),
    reason: "parity refund",
  }));

  // --- REVERSE-ORDER PROBES -------------------------------------------------
  //
  // The reverse guard (`reversePlanPurchase`) rejects 409 "Reverse newer
  // membership transactions first" when a NEWER non-reversed membership OR a
  // NEWER paid dues payment exists. These probes MUST run BEFORE the void
  // probes below consume the blocker, and an OLDER membership is reversed
  // FIRST so the guard actually fires.
  //
  // Seed timeline for member B (oldest → newest):
  //   t1 membershipIdB      (plan A, paymentIdB)
  //   t2 membershipIdZero   (zero-amount plan A, no payment)
  //   t3 paymentIdDues      (dues, paid)
  //   t4 membershipIdPlan2  (plan B, paymentIdPlan2)
  //
  // 1) Reverse the OLDER zero-amount membership first while the newer
  //    membership (t4, still active) AND the newer dues payment (t3, still
  //    paid) are both in place → expected 409.
  push(await runStep(session, "edge.reverseOrder.olderFirst", "POST", `/memberships/${ids.membershipIdZero}/reverse`, {
    requestId: createRequestId(),
    reason: "reverse older first (should 409)",
  }));

  // 2) Now reverse in correct newest-first order so the state stays consistent.
  push(await runStep(session, "edge.reverseOrder.newest", "POST", `/memberships/${ids.membershipIdPlan2}/reverse`, {
    requestId: createRequestId(),
    reason: "reverse newest",
  }));

  // 3) Void the dues payment AFTER the reverse-order probe so it never
  //    consumes the blocker for step 1. First void succeeds, second hits the
  //    "only paid payments can be voided" 409.
  push(await runStep(session, "edge.voidWrongStatus.first", "POST", `/payments/${ids.paymentIdDues}/void`, {
    requestId: createRequestId(),
    reason: "first",
  }));

  push(await runStep(session, "edge.voidWrongStatus.second", "POST", `/payments/${ids.paymentIdDues}/void`, {
    requestId: createRequestId(),
    reason: "second",
  }));

  // 4) With the newer membership reversed and the newer dues now voided, the
  //    remaining (newest → oldest) reversals succeed.
  push(await runStep(session, "edge.reverseOrder.older", "POST", `/memberships/${ids.membershipIdZero}/reverse`, {
    requestId: createRequestId(),
    reason: "reverse older",
  }));

  push(await runStep(session, "edge.reverse", "POST", `/memberships/${ids.membershipIdB}/reverse`, {
    requestId: createRequestId(),
    reason: "parity reverse",
  }));

  // --- READS (stable step names) ---

  push(await runStep(session, "gyms.list", "GET", "/gyms"));
  push(await runStep(session, "members.list.default", "GET", "/members"));
  push(await runStep(session, "members.list.active", "GET", "/members?status=active"));
  push(await runStep(session, "members.list.expired", "GET", "/members?status=expired"));
  push(await runStep(session, "members.list.expiring", "GET", "/members?status=expiring"));
  push(await runStep(session, "members.list.due", "GET", "/members?status=due"));
  push(await runStep(session, "members.list.search", "GET", "/members?search=WithPlan"));
  push(await runStep(session, "members.one", "GET", `/members/${ids.memberB}`));
  push(await runStep(session, "plans.list.stats", "GET", "/plans?includeStats=true"));
  push(await runStep(session, "plans.list.active", "GET", "/plans?status=active"));
  push(await runStep(session, "payments.list.byMember", "GET", `/payments?memberId=${ids.memberB}`));
  push(await runStep(session, "payments.list.byMonth", "GET", `/payments?month=${currentMonth}`));
  push(await runStep(session, "payments.list.combined", "GET", `/payments?memberId=${ids.memberB}&month=${currentMonth}`));
  push(await runStep(session, "memberships.list", "GET", `/memberships?memberId=${ids.memberB}`));
  push(await runStep(session, "dashboard.get", "GET", "/dashboard"));
  push(await runStep(session, "reports.get", "GET", `/reports?year=${currentYear}`));
  push(await runStep(session, "activity.list", "GET", "/activity?page=1&limit=50"));
  push(await runStep(session, "payments.one", "GET", `/payments/${ids.paymentIdPlan2}`));
  push(await runStep(session, "payments.delete", "DELETE", `/payments/${ids.paymentIdPlan2}`));

  return steps;
}
