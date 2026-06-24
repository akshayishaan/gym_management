import { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import { connectDB } from "@/lib/mongodb";
import Staff from "@/models/Staff";

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) return null;
        await connectDB();
        const staff = await Staff.findOne({ email: credentials.email, isActive: true });
        if (!staff) return null;
        const isValid = await staff.comparePassword(credentials.password);
        if (!isValid) return null;
        staff.lastLogin = new Date();
        await staff.save();
        return {
          id: staff._id.toString(),
          name: staff.name,
          email: staff.email,
          role: staff.role,
        };
      },
    }),
  ],
  callbacks: {
    // gymIds are intentionally NOT stored in the JWT. Gym membership is mutable
    // (gyms get created, shared, removed) so it is hydrated fresh from the DB on
    // every request in requireAuth() and fetched via /api/gyms on the client.
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        token.role = (user as { role?: string }).role;
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        const u = session.user as { id?: string; role?: string };
        u.id = token.id as string;
        u.role = token.role as string;
      }
      return session;
    },
  },
  pages: {
    signIn: "/login",
  },
  session: { strategy: "jwt" },
  secret: process.env.NEXTAUTH_SECRET,
};
