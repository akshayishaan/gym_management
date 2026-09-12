import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import type { Response } from "express";
import { ZodError } from "zod";
import { AuthError, DomainError, ForbiddenError } from "./errors";

interface MongoLikeError {
  code?: number;
  name?: string;
  keyPattern?: Record<string, unknown>;
  path?: string;
  message: string;
}

const isMongoLikeError = (value: unknown): value is MongoLikeError =>
  typeof value === "object" &&
  value !== null &&
  "code" in value &&
  typeof (value as { code: unknown }).code === "number";

/**
 * Single, centralized error mapper. Every thrown error — domain errors, auth
 * errors, Zod validation failures, and Mongoose driver errors — is normalized
 * into a consistent `{ error, details? }` response shape with the exact status
 * codes the Next.js `apiHandler` wrapper produced.
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();

    // Nest's own HttpException (route not found, method not allowed, etc.).
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      response.status(status).json({
        error: this.messageOf(exception) || HttpStatus[status],
      });
      return;
    }

    const status = this.resolveStatus(exception);

    if (status >= 500) {
      console.error("[API Error]", exception);
    }

    response.status(status).json(this.resolveBody(exception));
  }

  private resolveStatus(exception: unknown): number {
    if (exception instanceof DomainError) return exception.status;
    if (exception instanceof AuthError) return 401;
    if (exception instanceof ForbiddenError) return 403;
    if (exception instanceof ZodError) return 422;
    if (isMongoLikeError(exception)) {
      if (exception.code === 11000) return 409;
      if (exception.name === "ValidationError") return 422;
      if (exception.name === "CastError") return 400;
    }
    return 500;
  }

  private resolveBody(exception: unknown): { error: string; details?: unknown } {
    if (
      exception instanceof DomainError ||
      exception instanceof AuthError ||
      exception instanceof ForbiddenError
    ) {
      return { error: exception.message };
    }

    if (exception instanceof ZodError) {
      return {
        error: "Validation failed",
        details: exception.flatten().fieldErrors,
      };
    }

    if (isMongoLikeError(exception)) {
      if (exception.code === 11000) {
        const keys = Object.keys(exception.keyPattern ?? {}).join(", ");
        return { error: "Duplicate value for: " + (keys || "unknown") };
      }
      if (exception.name === "ValidationError") {
        return { error: exception.message };
      }
      if (exception.name === "CastError") {
        return {
          error: "Invalid ID format: " + (exception.path ?? "unknown"),
        };
      }
    }

    return { error: "Internal server error" };
  }

  private messageOf(exception: HttpException): string {
    const res = exception.getResponse();
    if (typeof res === "string") return res;
    if (typeof res === "object" && res !== null && "message" in res) {
      const message = (res as { message: unknown }).message;
      if (typeof message === "string") return message;
    }
    return "";
  }
}
