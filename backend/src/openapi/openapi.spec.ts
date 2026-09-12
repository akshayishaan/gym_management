import {
  extendZodWithOpenApi,
  OpenAPIRegistry,
  OpenApiGeneratorV3,
  type RouteConfig,
} from "@asteasolutions/zod-to-openapi";
import type { OpenAPIObject } from "openapi3-ts/oas30";
import { z } from "zod";
import {
  loginSchema,
  refreshSchema,
  signupSchema,
} from "../auth";
import { gymCreateSchema, gymUpdateSchema } from "../gyms";
import { memberCreateSchema, memberUpdateSchema } from "../members";
import { planCreateSchema, planUpdateSchema } from "../plans";
import { paymentActionSchema, paymentCreateSchema } from "../payments";

// Defensive: ensure the `.openapi` helper exists even if the generate function
// is somehow invoked without the main.ts side-effect import having run.
extendZodWithOpenApi(z);

/**
 * Builds the OpenAPI 3.0 document for contract/request fidelity, generated
 * from the same Zod schemas the controllers parse with (single source of
 * truth). Response bodies are intentionally omitted — no response Zod schemas
 * exist today — so every endpoint registers only a `description`.
 *
 * @see lib/* schema files for the authoritative request shapes.
 */
export function generateOpenApiDocument(): OpenAPIObject {
  const registry = new OpenAPIRegistry();

  // --- Request-body components (from existing Zod schemas) ---
  registry.register("SignupInput", signupSchema);
  registry.register("LoginInput", loginSchema);
  registry.register("RefreshInput", refreshSchema);
  registry.register("GymCreateInput", gymCreateSchema);
  registry.register("GymUpdateInput", gymUpdateSchema);
  registry.register("MemberCreateInput", memberCreateSchema);
  registry.register("MemberUpdateInput", memberUpdateSchema);
  registry.register("PlanCreateInput", planCreateSchema);
  registry.register("PlanUpdateInput", planUpdateSchema);
  registry.register("PaymentCreateInput", paymentCreateSchema);
  registry.register("PaymentActionInput", paymentActionSchema);

  const jsonBody = (schema: z.ZodTypeAny, description: string) => ({
    request: {
      body: {
        description,
        content: { "application/json": { schema } },
        required: true,
      },
    },
  });

  const ok = () => ({ 200: { description: "OK" } });
  const created = () => ({ 201: { description: "Created" } });

  // --- Endpoint surface (mirrors the controllers) ---
  const routes: RouteConfig[] = [
    { method: "post", path: "/auth/login", summary: "Log in", ...jsonBody(loginSchema, "Credentials"), responses: ok() },
    { method: "post", path: "/auth/signup", summary: "Create an account", ...jsonBody(signupSchema, "New account"), responses: created() },
    { method: "post", path: "/auth/refresh", summary: "Refresh access token", ...jsonBody(refreshSchema, "Refresh token"), responses: ok() },

    { method: "get", path: "/gyms", summary: "List gyms", responses: ok() },
    { method: "post", path: "/gyms", summary: "Create a gym", ...jsonBody(gymCreateSchema, "New gym"), responses: created() },
    { method: "get", path: "/gyms/{id}", summary: "Get a gym", responses: ok() },
    { method: "put", path: "/gyms/{id}", summary: "Update a gym", ...jsonBody(gymUpdateSchema, "Gym changes"), responses: ok() },
    { method: "delete", path: "/gyms/{id}", summary: "Delete a gym", responses: ok() },

    { method: "get", path: "/members", summary: "List members", responses: ok() },
    { method: "post", path: "/members", summary: "Create a member", ...jsonBody(memberCreateSchema, "New member"), responses: created() },
    { method: "get", path: "/members/{id}", summary: "Get a member", responses: ok() },
    { method: "put", path: "/members/{id}", summary: "Update a member", ...jsonBody(memberUpdateSchema, "Member changes"), responses: ok() },
    { method: "delete", path: "/members/{id}", summary: "Soft-delete a member", responses: ok() },

    { method: "get", path: "/plans", summary: "List plans", responses: ok() },
    { method: "post", path: "/plans", summary: "Create a plan", ...jsonBody(planCreateSchema, "New plan"), responses: created() },
    { method: "put", path: "/plans/{id}", summary: "Update a plan", ...jsonBody(planUpdateSchema, "Plan changes"), responses: ok() },

    { method: "get", path: "/payments", summary: "List payments", responses: ok() },
    { method: "post", path: "/payments", summary: "Record a payment", ...jsonBody(paymentCreateSchema, "New payment"), responses: created() },
    { method: "get", path: "/payments/{id}", summary: "Get a payment", responses: ok() },
    { method: "delete", path: "/payments/{id}", summary: "Delete a payment (rejected — audit record)", responses: ok() },
    { method: "post", path: "/payments/{id}/void", summary: "Void a payment", ...jsonBody(paymentActionSchema, "Void request"), responses: ok() },
    { method: "post", path: "/payments/{id}/refund", summary: "Refund a payment", ...jsonBody(paymentActionSchema, "Refund request"), responses: ok() },

    { method: "get", path: "/memberships", summary: "List memberships", responses: ok() },
    { method: "post", path: "/memberships/{id}/reverse", summary: "Reverse a plan purchase", ...jsonBody(paymentActionSchema, "Reversal request"), responses: ok() },

    { method: "get", path: "/dashboard", summary: "Gym dashboard summary", responses: ok() },
    { method: "get", path: "/reports", summary: "Annual gym report", responses: ok() },
    { method: "get", path: "/activity", summary: "Activity log", responses: ok() },
    { method: "get", path: "/health", summary: "Health check", responses: ok() },
  ];

  for (const route of routes) {
    registry.registerPath(route);
  }

  return new OpenApiGeneratorV3(registry.definitions).generateDocument({
    openapi: "3.0.0",
    info: {
      title: "Gym Management API",
      version: "0.1.0",
      description:
        "Multi-tenant gym management API. All endpoints are JSON; authenticated routes require a Bearer token.",
    },
    servers: [{ url: "/" }],
  });
}
