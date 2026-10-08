import "reflect-metadata";
import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { generateOpenApiDocument } from "../src/openapi/openapi.spec";

/**
 * Deterministic snapshot of the OpenAPI 3.0 document, committed as the single
 * source of truth for client codegen. Built from the exact same Zod schemas
 * the controllers parse with (via `generateOpenApiDocument`).
 */
const outputPath = join(__dirname, "..", "openapi.json");

try {
  const document = generateOpenApiDocument();
  writeFileSync(outputPath, `${JSON.stringify(document, null, 2)}\n`, "utf8");
  console.log(`Wrote OpenAPI document to ${outputPath}`);
} catch (error) {
  console.error("Failed to export OpenAPI document:", error);
  process.exit(1);
}
