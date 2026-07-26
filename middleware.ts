import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { getToken } from "next-auth/jwt";
import { isMobileUserAgent } from "@/lib/deviceDetect";

/**
 * Next.js middleware for device gating + authentication protection.
 * - Blocks non-mobile User-Agents (desktop, tablets) to /unsupported-device
 * - Redirects unauthenticated users from /dashboard/* to /login
 * - Redirects authenticated users from /login to /dashboard
 * - Allows API routes and static assets through
 *
 * The active gym is not defaulted here: gymIds are no longer in the JWT, so the
 * server resolves the selected gym from the cookie in getSelectedGymId(),
 * falling back to the user's first gym (read from the DB) when no cookie is set.
 */
export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // API routes are already excluded by the matcher below; this only needs to
  // let through static files (manifest, icons, anything with an extension)
  // that the matcher's negative lookahead doesn't cover.
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/favicon") ||
    pathname.startsWith("/manifest") ||
    pathname.startsWith("/icons") ||
    pathname.includes(".")
  ) {
    return NextResponse.next();
  }

  // Device gate — this is a mobile-only app. Runs before auth so desktop
  // visitors never even reach /login.
  if (pathname !== "/unsupported-device" && !isMobileUserAgent(req.headers.get("user-agent"))) {
    return NextResponse.redirect(new URL("/unsupported-device", req.url));
  }

  // Check for JWT token (works with next-auth v4 JWT strategy)
  const token = await getToken({
    req,
    secret: process.env.NEXTAUTH_SECRET,
  });

  // Redirect unauthenticated users to login (except if already on login)
  if (!token && pathname.startsWith("/dashboard")) {
    const loginUrl = new URL("/login", req.url);
    loginUrl.searchParams.set("callbackUrl", pathname);
    return NextResponse.redirect(loginUrl);
  }

  // Redirect authenticated users away from login page
  if (token && pathname === "/login") {
    return NextResponse.redirect(new URL("/dashboard", req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
