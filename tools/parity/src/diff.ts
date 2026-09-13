import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { normalizeValue, stableSerialize } from "./normalize";
import type { Transcript, TranscriptStep } from "./types";

const OUT_DIR = join(__dirname, "..", "out");

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

/** Maximum number of leaf-level differences printed per failing step. */
const MAX_DIFFS = 20;

/**
 * Recursively diffs two normalized values, collecting every leaf-level
 * difference string of the form `path: next=... vs nest=...`. Callers are
 * responsible for truncating the result for display (see `reportDiffs`).
 */
export function diffValues(next: unknown, nest: unknown, path: string, out: string[] = []): string[] {
  const nextIsObject = isPlainObject(next);
  const nestIsObject = isPlainObject(nest);

  if (nextIsObject && nestIsObject) {
    const keys = new Set([...Object.keys(next), ...Object.keys(nest)]);
    for (const key of [...keys].sort()) {
      const nextHas = key in next;
      const nestHas = key in nest;
      if (!nextHas || !nestHas) {
        out.push(`${path === "" ? key : `${path}.${key}`}: next=${format(!nextHas ? "<missing>" : next[key])} vs nest=${format(!nestHas ? "<missing>" : nest[key])}`);
      } else {
        diffValues(next[key], nest[key], path === "" ? key : `${path}.${key}`, out);
      }
    }
    return out;
  }

  if (stableSerialize(next) !== stableSerialize(nest)) {
    out.push(`${path || "<root>"}: next=${format(next)} vs nest=${format(nest)}`);
  }
  return out;
}

/**
 * Renders up to `MAX_DIFFS` differences on one line, appending a trailing
 * `…and N more difference(s)` when truncated so root-causes aren't hidden.
 */
function reportDiffs(differences: string[]): string {
  if (differences.length <= MAX_DIFFS) {
    return differences.join("; ");
  }
  const shown = differences.slice(0, MAX_DIFFS).join("; ");
  const remaining = differences.length - MAX_DIFFS;
  const noun = remaining === 1 ? "difference" : "differences";
  return `${shown}; …and ${remaining} more ${noun}`;
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== "object") return false;
  const proto = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === null;
}

function format(value: unknown): string {
  if (value === undefined) return "<undefined>";
  if (value === null) return "null";
  if (typeof value === "string") return `"${value}"`;
  return stableSerialize(value);
}

function main(): void {
  const runId = requiredEnv("RUN_ID");
  const nextTranscript = loadTranscript(runId, "next");
  const nestTranscript = loadTranscript(runId, "nest");

  const nestByStep = new Map<string, TranscriptStep>(
    nestTranscript.steps.map((step) => [step.step, step]),
  );

  let passed = 0;
  let failed = 0;
  let skipped = 0;
  const total = nextTranscript.steps.length;

  // Preserve `next` order; join nest steps by name.
  for (const nextStep of nextTranscript.steps) {
    if (nextStep.skipDiff) {
      skipped += 1;
      continue;
    }

    const nestStep = nestByStep.get(nextStep.step);
    if (!nestStep) {
      failed += 1;
      console.log(`FAIL  ${nextStep.step}: missing in nest transcript`);
      continue;
    }

    const nextBody = normalizeValue(nextStep.body, nextStep.step);
    const nestBody = normalizeValue(nestStep.body, nestStep.step);
    const statusEqual = nextStep.status === nestStep.status;
    const bodyEqual = stableSerialize(nextBody) === stableSerialize(nestBody);

    if (statusEqual && bodyEqual) {
      passed += 1;
      console.log(`PASS  ${nextStep.step}`);
      continue;
    }

    failed += 1;
    const differences: string[] = [];
    if (!statusEqual) {
      differences.push(`status: next=${nextStep.status} vs nest=${nestStep.status}`);
    }
    if (!bodyEqual) {
      differences.push(...diffValues(nextBody, nestBody, ""));
    }
    console.log(`FAIL  ${nextStep.step}: ${reportDiffs(differences)}`);
  }

  console.log(`\npassed ${passed}, failed ${failed}, skipped ${skipped} of ${total}`);
  process.exitCode = failed === 0 ? 0 : 1;
}

main();
