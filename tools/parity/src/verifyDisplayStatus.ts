import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import {
  calendarDaysBetween,
  calculateMembershipExpiry,
  membershipStatus,
  todayInGymTz,
} from "./displayStatus";
import type { Transcript, TranscriptStep } from "./types";

const OUT_DIR = join(__dirname, "..", "out");

// Seed constants — must match `scenario.ts` (plan A = 30 days, onboarded with
// `membershipStart: today`).
const PLAN_A_DURATION_DAYS = 30;

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.trim() === "") {
    throw new Error(`missing required env var ${name}`);
  }
  return value.trim();
}

function loadTranscript(runId: string, backend: "next" | "nest"): Transcript {
  const path = join(OUT_DIR, `parity.${runId}.${backend}.json`);
  if (!existsSync(path)) {
    throw new Error(`transcript ${path} not found — run the "${backend}" backend first`);
  }
  return JSON.parse(readFileSync(path, "utf8")) as Transcript;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function format(value: unknown): string {
  if (value === undefined) return "<undefined>";
  if (value === null) return "null";
  if (typeof value === "string") return JSON.stringify(value);
  return String(value);
}

let failures = 0;

/** Records a single assertion, printing PASS/FAIL and tracking the exit code. */
function check(condition: boolean, label: string, detail: string): void {
  if (!condition) failures += 1;
  const mark = condition ? "PASS" : "FAIL";
  console.log(`${mark}  ${label}${detail === "" ? "" : ` — ${detail}`}`);
}

function stepNamed(steps: TranscriptStep[], name: string): TranscriptStep | undefined {
  return steps.find((step) => step.step === name);
}

/**
 * Verifies the NestJS-only server-computed display-status fields (ADR-0005)
 * against the canonical calendar math, re-derived from the seed's known dates.
 *
 * The Next.js API does not return these fields (the web computes them
 * client-side), so we can only assert them against the NEST transcript.
 */
function main(): void {
  const runId = requiredEnv("RUN_ID");
  const nest = loadTranscript(runId, "nest");

  const today = todayInGymTz();
  const planAExpiry = calculateMembershipExpiry(today, PLAN_A_DURATION_DAYS);
  const planAExpectedStatus = membershipStatus(planAExpiry, today);
  const planAExpectedDays = calendarDaysBetween(today, planAExpiry);

  // --- 1. members.one (member B: plan A, 30 days, membershipStart today) ----
  const memberOne = stepNamed(nest.steps, "members.one");
  if (!memberOne) {
    check(false, "members.one step present", "missing in nest transcript");
  } else if (!isRecord(memberOne.body)) {
    check(false, "members.one body is an object", `got ${format(memberOne.body)}`);
  } else {
    const member = memberOne.body;
    check(
      member.status === planAExpectedStatus,
      "members.one member.status",
      `expected ${format(planAExpectedStatus)}, got ${format(member.status)}`
    );
    check(
      member.daysUntilExpiry === planAExpectedDays,
      "members.one member.daysUntilExpiry",
      `expected ${format(planAExpectedDays)}, got ${format(member.daysUntilExpiry)}`
    );
  }

  // --- 2. member with no plan: status/daysUntilExpiry must be ABSENT ---------
  //
  // The scenario has no `members.one` for the no-plan member (member A only
  // appears in the list), so we locate it inside `members.list.default` — the
  // member entry lacking a `membershipExpiry`.
  const listDefault = stepNamed(nest.steps, "members.list.default");
  if (!listDefault) {
    check(false, "members.list.default step present", "missing in nest transcript");
  } else {
    const members = isRecord(listDefault.body) ? listDefault.body.members : undefined;
    const noPlanMember = Array.isArray(members)
      ? members.map((m) => (isRecord(m) ? m : undefined)).find((m) => m && m.membershipExpiry === undefined)
      : undefined;
    if (!noPlanMember) {
      check(false, "members.list.default contains a no-plan member", "no member without membershipExpiry");
    } else {
      check(
        noPlanMember.status === undefined && noPlanMember.daysUntilExpiry === undefined,
        "no-plan member has no status/daysUntilExpiry",
        `status=${format(noPlanMember.status)}, daysUntilExpiry=${format(noPlanMember.daysUntilExpiry)}`
      );
    }
  }

  // --- 3. memberships.list (member B): the plan-A membership ----------------
  const membershipsStep = stepNamed(nest.steps, "memberships.list");
  if (!membershipsStep) {
    check(false, "memberships.list step present", "missing in nest transcript");
  } else {
    const memberships = isRecord(membershipsStep.body) ? membershipsStep.body.memberships : undefined;
    const planAMembership = Array.isArray(memberships)
      ? memberships
          .map((m) => (isRecord(m) ? m : undefined))
          .find((m) => m && m.durationDays === PLAN_A_DURATION_DAYS)
      : undefined;
    if (!planAMembership) {
      check(false, "memberships.list contains a plan-A membership", `no membership with durationDays=${PLAN_A_DURATION_DAYS}`);
    } else {
      check(
        planAMembership.expiryStatus === planAExpectedStatus,
        "memberships.list plan-A expiryStatus",
        `expected ${format(planAExpectedStatus)}, got ${format(planAMembership.expiryStatus)}`
      );
      const { startDate, expiryDate } = planAMembership;
      if (typeof startDate === "string" && typeof expiryDate === "string") {
        const expectedDuration = calendarDaysBetween(startDate, expiryDate) + 1;
        check(
          planAMembership.durationDays === expectedDuration,
          "memberships.list plan-A durationDays",
          `expected ${format(expectedDuration)}, got ${format(planAMembership.durationDays)}`
        );
      } else {
        check(false, "memberships.list plan-A has startDate/expiryDate", `startDate=${format(startDate)}, expiryDate=${format(expiryDate)}`);
      }
    }
  }

  // --- 4. dashboard.get: expiringList[].daysUntilExpiry ----------------------
  const dashboardStep = stepNamed(nest.steps, "dashboard.get");
  if (!dashboardStep) {
    check(false, "dashboard.get step present", "missing in nest transcript");
  } else {
    const expiringList = isRecord(dashboardStep.body) ? dashboardStep.body.expiringList : undefined;
    if (!Array.isArray(expiringList)) {
      check(false, "dashboard.get expiringList is an array", `got ${format(expiringList)}`);
    } else if (expiringList.length === 0) {
      console.log("NOTE  dashboard.get expiringList is empty — no daysUntilExpiry to verify");
    } else {
      expiringList.forEach((raw, index) => {
        const item = isRecord(raw) ? raw : undefined;
        if (!item || typeof item.membershipExpiry !== "string") {
          check(false, `dashboard.get expiringList[${index}] has membershipExpiry`, `got ${format(raw)}`);
          return;
        }
        const expectedDays = calendarDaysBetween(today, item.membershipExpiry);
        check(
          item.daysUntilExpiry === expectedDays,
          `dashboard.get expiringList[${index}].daysUntilExpiry`,
          `expected ${format(expectedDays)}, got ${format(item.daysUntilExpiry)}`
        );
      });
    }
  }

  console.log("");
  if (failures === 0) {
    console.log("verify-display-status: all assertions passed");
  } else {
    console.log(`verify-display-status: ${failures} assertion(s) failed`);
  }
  process.exitCode = failures === 0 ? 0 : 1;
}

main();
