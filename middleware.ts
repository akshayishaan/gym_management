import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { getToken } from "next-auth/jwt";

/**
 * Next.js middleware for authentication protection.
 * - Redirects unauthenticated users from /dashboard/* to /login
 * - Redirects authenticated users from /login to /dashboard
 * - Sets default selectedGymId cookie if missing
 * - Allows API routes and static assets through
 */
export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // Allow auth API routes, static files, and _next internals
  if (
    pathname.startsWith("/api/auth") ||
    pathname.startsWith("/_next") ||
    pathname.startsWith("/favicon") ||
    pathname.includes(".")
  ) {
    return NextResponse.next();
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

  // Set default selectedGymId cookie if user is authenticated and cookie is missing
  if (token && pathname.startsWith("/dashboard")) {
    const selectedGymId = req.cookies.get("selectedGymId")?.value;
    const gymIds = (token.gymIds as string[]) ?? [];
    const role = token.role as string;

    if (!selectedGymId && role !== "superadmin" && gymIds.length > 0) {
      const response = NextResponse.next();
      response.cookies.set("selectedGymId", gymIds[0], {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "lax",
        path: "/",
        maxAge: 30 * 24 * 60 * 60, // 30 days
      });
      return response;
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*", "/login"],
};
