import { NextRequest, NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import Staff from "@/models/Staff";
import { z } from "zod";

const signupSchema = z.object({
  name: z.string().min(1, "Name is required").max(100).trim(),
  email: z.string().email("Invalid email"),
  password: z.string().min(6, "Password must be at least 6 characters"),
});

export async function POST(req: NextRequest) {
  try {
    await connectDB();
    const body = await req.json();
    const validated = signupSchema.parse(body);

    const existing = await Staff.findOne({ email: validated.email.toLowerCase() });
    if (existing) {
      return NextResponse.json({ error: "An account with this email already exists" }, { status: 409 });
    }

    await Staff.create({
      name: validated.name,
      email: validated.email,
      password: validated.password,  // hashed by pre-save hook
      role: "admin",
      gymIds: [],
      isActive: true,
    });

    return NextResponse.json({ message: "Account created successfully" }, { status: 201 });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return NextResponse.json({ error: err.flatten().fieldErrors }, { status: 422 });
    }
    console.error("[signup]", err);
    return NextResponse.json({ error: "Something went wrong" }, { status: 500 });
  }
}
