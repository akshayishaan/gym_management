import {
  extendZodWithOpenApi,
  OpenAPIRegistry,
  OpenApiGeneratorV3,
  type RouteConfig,
} from "@asteasolutions/zod-to-openapi";
import type { OpenAPIObject } from "openapi3-ts/oas30";
import { z } from "zod";
import { loginSchema, refreshSchema, signupSchema } from "../auth";
import { gymCreateSchema, gymUpdateSchema } from "../gyms";
import { memberCreateSchema, memberUpdateSchema } from "../members";
import { planCreateSchema, planUpdateSchema } from "../plans";
import { paymentActionSchema, paymentCreateSchema } from "../payments";
import {
  activityListResponseSchema,
  activityLogResponseSchema,
  authSessionResponseSchema,
  dashboardResponseSchema,
  errorResponseSchema,
  gymResponseSchema,
  healthResponseSchema,
  lifecycleResultResponseSchema,
  memberCreateResponseSchema,
  memberListResponseSchema,
  memberResponseSchema,
  membershipListResponseSchema,
  membershipResponseSchema,
  paymentCreateResponseSchema,
  paymentListItemResponseSchema,
  paymentListResponseSchema,
  paymentResponseSchema,
  planListItemResponseSchema,
  planListResponseSchema,
  planResponseSchema,
  reportsResponseSchema,
  signupResponseSchema,
  successResponseSchema,
} from "./openapi.responseSchemas";

// Defensive: ensure the `.openapi` helper exists even if the generate function
// is somehow invoked without the main.ts side-effect import having run.
extendZodWithOpenApi(z);

/**
 * Builds the OpenAPI 3.0 document for contract/request fidelity, generated
 * from the same Zod schemas the controllers parse with (single source of
 * truth). Response bodies are now encoded too — see
 * `openapi.responseSchemas.ts` — so the generated Dart client is fully typed.
 *
 * `registry.register()` tags a schema with a component refId and returns a
 * copy of the schema carrying that refId. Referencing the *returned* schema in
 * a route (rather than the original) makes the generator emit a `$ref` to
 * `#/components/schemas/...` instead of inlining the schema under the path
 * operation. The components therefore stay registered (so the `$ref` resolves)
 * while the operations stay lean.
 *
 * @see lib/* schema files for the authoritative request shapes.
 * @see openapi.responseSchemas.ts for the response shapes.
 */
export function generateOpenApiDocument(): OpenAPIObject {
  const registry = new OpenAPIRegistry();

  // --- Request-body components (from existing Zod schemas) ---
  const SignupInput = registry.register("SignupInput", signupSchema);
  const LoginInput = registry.register("LoginInput", loginSchema);
  const RefreshInput = registry.register("RefreshInput", refreshSchema);
  const GymCreateInput = registry.register("GymCreateInput", gymCreateSchema);
  const GymUpdateInput = registry.register("GymUpdateInput", gymUpdateSchema);
  const MemberCreateInput = registry.register("MemberCreateInput", memberCreateSchema);
  const MemberUpdateInput = registry.register("MemberUpdateInput", memberUpdateSchema);
  const PlanCreateInput = registry.register("PlanCreateInput", planCreateSchema);
  const PlanUpdateInput = registry.register("PlanUpdateInput", planUpdateSchema);
  const PaymentCreateInput = registry.register("PaymentCreateInput", paymentCreateSchema);
  const PaymentActionInput = registry.register("PaymentActionInput", paymentActionSchema);

  // --- Response components ---
  const ErrorResponse = registry.register("ErrorResponse", errorResponseSchema);
  const SuccessResponse = registry.register("SuccessResponse", successResponseSchema);
  const AuthSessionResponse = registry.register("AuthSessionResponse", authSessionResponseSchema);
  const SignupResponse = registry.register("SignupResponse", signupResponseSchema);
  const GymResponse = registry.register("GymResponse", gymResponseSchema);
  const MemberResponse = registry.register("MemberResponse", memberResponseSchema);
  const MemberListResponse = registry.register("MemberListResponse", memberListResponseSchema);
  const MemberCreateResponse = registry.register("MemberCreateResponse", memberCreateResponseSchema);
  const PaymentResponse = registry.register("PaymentResponse", paymentResponseSchema);
  registry.register("PaymentListItemResponse", paymentListItemResponseSchema);
  const PaymentListResponse = registry.register("PaymentListResponse", paymentListResponseSchema);
  const PaymentCreateResponse = registry.register("PaymentCreateResponse", paymentCreateResponseSchema);
  const LifecycleResultResponse = registry.register("LifecycleResultResponse", lifecycleResultResponseSchema);
  const PlanResponse = registry.register("PlanResponse", planResponseSchema);
  registry.register("PlanListItemResponse", planListItemResponseSchema);
  const PlanListResponse = registry.register("PlanListResponse", planListResponseSchema);
  registry.register("MembershipResponse", membershipResponseSchema);
  const MembershipListResponse = registry.register("MembershipListResponse", membershipListResponseSchema);
  const DashboardResponse = registry.register("DashboardResponse", dashboardResponseSchema);
  const ReportsResponse = registry.register("ReportsResponse", reportsResponseSchema);
  registry.register("ActivityLogResponse", activityLogResponseSchema);
  const ActivityListResponse = registry.register("ActivityListResponse", activityListResponseSchema);
  const HealthResponse = registry.register("HealthResponse", healthResponseSchema);

  const jsonBody = (
    schema: z.ZodTypeAny,
    description: string,
    params?: z.ZodObject<z.ZodRawShape>,
  ) => ({
    request: {
      body: {
        description,
        content: { "application/json": { schema } },
        required: true,
      },
      ...(params ? { params } : {}),
    },
  });

  const pathParams = (params: z.ZodObject<z.ZodRawShape>) => ({
    request: { params },
  });

  const json = (schema: z.ZodTypeAny, description: string) => ({
    description,
    content: { "application/json": { schema } },
  });

  // `{id}` path parameter, serialized as a Mongo ObjectId string.
  const idParams = z.object({ id: z.string() });

  // --- Endpoint surface (mirrors the controllers) ---
  const routes: RouteConfig[] = [
    {
      method: "post",
      path: "/auth/login",
      summary: "Log in",
      ...jsonBody(LoginInput, "Credentials"),
      responses: { 200: json(AuthSessionResponse, "Authentication session") },
    },
    {
      method: "post",
      path: "/auth/signup",
      summary: "Create an account",
      ...jsonBody(SignupInput, "New account"),
      responses: { 201: json(SignupResponse, "Account created") },
    },
    {
      method: "post",
      path: "/auth/refresh",
      summary: "Refresh access token",
      ...jsonBody(RefreshInput, "Refresh token"),
      responses: { 200: json(AuthSessionResponse, "Authentication session") },
    },

    {
      method: "get",
      path: "/gyms",
      summary: "List gyms",
      responses: { 200: json(z.array(GymResponse), "List of gyms") },
    },
    {
      method: "post",
      path: "/gyms",
      summary: "Create a gym",
      ...jsonBody(GymCreateInput, "New gym"),
      responses: { 201: json(GymResponse, "Created gym") },
    },
    {
      method: "get",
      path: "/gyms/{id}",
      summary: "Get a gym",
      ...pathParams(idParams),
      responses: { 200: json(GymResponse, "Gym") },
    },
    {
      method: "put",
      path: "/gyms/{id}",
      summary: "Update a gym",
      ...jsonBody(GymUpdateInput, "Gym changes", idParams),
      responses: { 200: json(GymResponse, "Updated gym") },
    },
    {
      method: "delete",
      path: "/gyms/{id}",
      summary: "Delete a gym",
      ...pathParams(idParams),
      responses: { 200: json(SuccessResponse, "Deletion result") },
    },

    {
      method: "get",
      path: "/members",
      summary: "List members",
      responses: { 200: json(MemberListResponse, "Paginated members") },
    },
    {
      method: "post",
      path: "/members",
      summary: "Create a member",
      ...jsonBody(MemberCreateInput, "New member"),
      responses: { 201: json(MemberCreateResponse, "Created member") },
    },
    {
      method: "get",
      path: "/members/{id}",
      summary: "Get a member",
      ...pathParams(idParams),
      responses: { 200: json(MemberResponse, "Member") },
    },
    {
      method: "put",
      path: "/members/{id}",
      summary: "Update a member",
      ...jsonBody(MemberUpdateInput, "Member changes", idParams),
      responses: { 200: json(MemberResponse, "Updated member") },
    },
    {
      method: "delete",
      path: "/members/{id}",
      summary: "Soft-delete a member",
      ...pathParams(idParams),
      responses: { 200: json(SuccessResponse, "Deletion result") },
    },

    {
      method: "get",
      path: "/plans",
      summary: "List plans",
      responses: { 200: json(PlanListResponse, "Paginated plans") },
    },
    {
      method: "post",
      path: "/plans",
      summary: "Create a plan",
      ...jsonBody(PlanCreateInput, "New plan"),
      responses: { 201: json(PlanResponse, "Created plan") },
    },
    {
      method: "put",
      path: "/plans/{id}",
      summary: "Update a plan",
      ...jsonBody(PlanUpdateInput, "Plan changes", idParams),
      responses: { 200: json(PlanResponse, "Updated plan") },
    },

    {
      method: "get",
      path: "/payments",
      summary: "List payments",
      responses: { 200: json(PaymentListResponse, "Paginated payments") },
    },
    {
      method: "post",
      path: "/payments",
      summary: "Record a payment",
      ...jsonBody(PaymentCreateInput, "New payment"),
      responses: { 201: json(PaymentCreateResponse, "Recorded payment") },
    },
    {
      method: "get",
      path: "/payments/{id}",
      summary: "Get a payment",
      ...pathParams(idParams),
      responses: { 200: json(PaymentResponse, "Payment") },
    },
    {
      method: "delete",
      path: "/payments/{id}",
      summary: "Delete a payment (rejected — audit record)",
      ...pathParams(idParams),
      responses: { 405: json(ErrorResponse, "Method Not Allowed") },
    },
    {
      method: "post",
      path: "/payments/{id}/void",
      summary: "Void a payment",
      ...jsonBody(PaymentActionInput, "Void request", idParams),
      responses: { 200: json(LifecycleResultResponse, "Void result") },
    },
    {
      method: "post",
      path: "/payments/{id}/refund",
      summary: "Refund a payment",
      ...jsonBody(PaymentActionInput, "Refund request", idParams),
      responses: { 200: json(LifecycleResultResponse, "Refund result") },
    },

    {
      method: "get",
      path: "/memberships",
      summary: "List memberships",
      responses: { 200: json(MembershipListResponse, "Memberships") },
    },
    {
      method: "post",
      path: "/memberships/{id}/reverse",
      summary: "Reverse a plan purchase",
      ...jsonBody(PaymentActionInput, "Reversal request", idParams),
      responses: { 200: json(LifecycleResultResponse, "Reversal result") },
    },

    {
      method: "get",
      path: "/dashboard",
      summary: "Gym dashboard summary",
      responses: { 200: json(DashboardResponse, "Dashboard summary") },
    },
    {
      method: "get",
      path: "/reports",
      summary: "Annual gym report",
      responses: { 200: json(ReportsResponse, "Annual report") },
    },
    {
      method: "get",
      path: "/activity",
      summary: "Activity log",
      responses: { 200: json(ActivityListResponse, "Paginated activity log") },
    },
    {
      method: "get",
      path: "/health",
      summary: "Health check",
      responses: { 200: json(HealthResponse, "Health status") },
    },
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
