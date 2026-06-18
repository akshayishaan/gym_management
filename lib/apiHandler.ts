import { NextRequest, NextResponse } from "next/server";
import { AuthError, ForbiddenError } from "@/lib/withAuth";
import { ZodError } from "zod";
import { getSelectedGymId } from "@/lib/selectedGym";

/**
 * Standardized API error response shape.
 */
interface ApiError {
  error: string;
  details?: unknown;
}

/**
 * Wraps an API route handler with centralized error handling.
 * Catches AuthError, ForbiddenError, ZodError, and unknown errors.
 * Also injects user.selectedGymId from the selectedGymId cookie.
 *
 * Usage:
 * ```ts
 * export const GET = apiHandler(async (req, user) => { ... });
 * export const POST = apiHandler(async (req, user) => { ... });
 * ```
 */
export function apiHandler(
  handler: (req: NextRequest, user: import("@/lib/session").SessionUser) => Promise<NextResponse>
): (req: NextRequest) => Promise<NextResponse> {
  return async (req: NextRequest) => {
    try {
      const { requireAuth } = await import("@/lib/withAuth");
      const user = await requireAuth();

      // Inject selectedGymId from cookie
      const selectedGymId = getSelectedGymId(req, user);
      if (selectedGymId) {
        user.selectedGymId = selectedGymId;
      }

      return await handler(req, user);
    } catch (err) {
      return handleError(err);
    }
  };
}

/**
 * For route handlers that also receive params (dynamic routes like [id]).
 * The params are extracted from the second argument.
 * Also injects user.selectedGymId from the selectedGymId cookie.
 *
 * Usage:
 * ```ts
 * export const PUT = apiHandlerWithParams(async (req, user, { id }) => { ... });
 * ```
 */
export function apiHandlerWithParams<TParams>(
  handler: (
    req: NextRequest,
    user: import("@/lib/session").SessionUser,
    params: TParams
  ) => Promise<NextResponse>
): (
  req: NextRequest,
  context: { params: Promise<TParams> }
) => Promise<NextResponse> {
  return async (req: NextRequest, context: { params: Promise<TParams> }) => {
    try {
      const { requireAuth } = await import("@/lib/withAuth");
      const user = await requireAuth();
      const params = await context.params;

      // Inject selectedGymId from cookie
      const selectedGymId = getSelectedGymId(req, user);
      if (selectedGymId) {
        user.selectedGymId = selectedGymId;
      }

      return await handler(req, user, params);
    } catch (err) {
      return handleError(err);
    }
  };
}

/**
 * Centralized error handler used by both apiHandler and apiHandlerWithParams.
 */
function handleError(err: unknown): NextResponse<ApiError> {
  if (err instanceof AuthError) {
    return NextResponse.json<ApiError>(
      { error: err.message },
      { status: 401 }
    );
  }
  if (err instanceof ForbiddenError) {
    return NextResponse.json<ApiError>(
      { error: err.message },
      { status: 403 }
    );
  }
  if (err instanceof ZodError) {
    return NextResponse.json<ApiError>(
      {
        error: "Validation failed",
        details: err.flatten().fieldErrors,
      },
      { status: 422 }
    );
  }
  if (err instanceof Error && err.message === "No gymId on session") {
    return NextResponse.json<ApiError>(
      { error: "No gymId on session" },
      { status: 403 }
    );
  }
  // Mongoose duplicate key
  if (err instanceof Error && "code" in err && (err as { code: number }).code === 11000) {
    const field = (err as { keyPattern?: Record<string, unknown> }).keyPattern;
    const fieldNames = field ? Object.keys(field).join(", ") : "unknown";
    return NextResponse.json<ApiError>(
      { error: `Duplicate value for: ${fieldNames}` },
      { status: 409 }
    );
  }
  // Mongoose validation error
  if (err instanceof Error && err.name === "ValidationError") {
    return NextResponse.json<ApiError>(
      { error: err.message },
      { status: 422 }
    );
  }
  // Mongoose cast error
  if (err instanceof Error && err.name === "CastError") {
    return NextResponse.json<ApiError>(
      { error: `Invalid ID format: ${(err as { path?: string }).path || "unknown"}` },
      { status: 400 }
    );
  }
  // Generic fallback
  console.error("[API Error]", err);
  return NextResponse.json<ApiError>(
    { error: "Internal server error" },
    { status: 500 }
  );
}
