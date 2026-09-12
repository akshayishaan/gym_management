import { extendZodWithOpenApi } from "@asteasolutions/zod-to-openapi";
import { z } from "zod";

// Registered exactly-once at boot (from main.ts) so every Zod schema gains the
// `.openapi(...)` helper used to attach request-contract metadata.
extendZodWithOpenApi(z);
