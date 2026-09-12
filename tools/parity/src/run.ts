import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { createNextAuthSession } from "./nextAuth";
import { createNestAuthSession } from "./nestAuth";
import { seed, probeAndRead } from "./scenario";
import type { Backend, Transcript } from "./types";

const OUT_DIR = join(__dirname, "..", "out");

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.trim() === "") {
    throw new Error(`missing required env var ${name}`);
  }
  return value.trim();
}

function optionalEnv(name: string, fallback: string): string {
  const value = process.env[name];
  return value && value.trim() !== "" ? value.trim() : fallback;
}

function transcriptFilePath(runId: string, backend: Backend): string {
  return join(OUT_DIR, `parity.${runId}.${backend}.json`);
}

async function authenticate(backend: Backend, base: string, email: string, password: string, name: string) {
  return backend === "nest"
    ? createNestAuthSession(base, email, password, name)
    : createNextAuthSession(base, email, password, name);
}

async function main(): Promise<void> {
  const backend = requiredEnv("BACKEND") as Backend;
  if (backend !== "next" && backend !== "nest") {
    throw new Error(`BACKEND must be "next" or "nest", got "${backend}"`);
  }

  const runId = requiredEnv("RUN_ID");
  const base = backend === "nest"
    ? optionalEnv("NEST_BASE", "http://localhost:3001")
    : optionalEnv("NEXT_BASE", "http://localhost:3000");
  // Each backend run signs up its OWN admin (backend-distinct email), so the
  // two runs share an Atlas cluster but are isolated by gym scoping. The two
  // seeds never collide and never mutate each other's data.
  const email = optionalEnv("EMAIL", `parity+${runId}+${backend}@example.com`);
  const password = optionalEnv("PASSWORD", "Admin123!");
  const adminName = optionalEnv("ADMIN_NAME", "Parity Admin");

  const session = await authenticate(backend, base, email, password, adminName);

  // Seed FRESH per backend run: this run creates its own gym + plans +
  // members (scoped to its own admin) and then replays the full probe/read
  // sequence against them. The normalization layer masks volatile ids, so the
  // two independent seeds produce diffable transcripts. There is no shared
  // seed sidecar and no "run next first" ordering requirement.
  const ids = await seed(runId, session);

  const steps = await probeAndRead(runId, session, ids);
  const transcript: Transcript = { backend, runId, steps };

  mkdirSync(OUT_DIR, { recursive: true });
  const outPath = transcriptFilePath(runId, backend);
  writeFileSync(outPath, JSON.stringify(transcript, null, 2), "utf8");

  console.log(`wrote ${steps.length} steps to ${outPath}`);
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`[parity] ${message}`);
  process.exitCode = 1;
});
