/**
 * Domain-level error classes, mirroring the Next.js `lib/domainError.ts` and
 * `lib/withAuth.ts` error surface exactly.
 *
 * `DomainError` carries a configurable HTTP status (default 400) for business
 * rule violations. `AuthError` and `ForbiddenError` are fixed at 401/403 for
 * authentication and authorization failures respectively.
 */
export class DomainError extends Error {
  constructor(
    message: string,
    public readonly status: number = 400,
  ) {
    super(message);
    this.name = "DomainError";
  }
}

export class AuthError extends Error {
  status = 401;

  constructor(message = "Unauthorized") {
    super(message);
    this.name = "AuthError";
  }
}

export class ForbiddenError extends Error {
  status = 403;

  constructor(message = "Forbidden") {
    super(message);
    this.name = "ForbiddenError";
  }
}
