import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017/gym_management";
const ADMIN_EMAIL = process.env.SEED_ADMIN_EMAIL || "admin@gym.com";
const ADMIN_PASSWORD = process.env.SEED_ADMIN_PASSWORD || "admin123";

async function seed() {
  await mongoose.connect(MONGODB_URI);
  console.log("Connected to MongoDB");

  const db = mongoose.connection.db!;

  const existing = await db.collection("staffs").findOne({ email: ADMIN_EMAIL });
  if (!existing) {
    const hashed = await bcrypt.hash(ADMIN_PASSWORD, 12);
    await db.collection("staffs").insertOne({
      name: "Admin",
      email: ADMIN_EMAIL,
      password: hashed,
      role: "admin",
      gymIds: [],
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    console.log(`Admin created: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
  } else {
    console.log("Admin already exists, skipping.");
  }

  await mongoose.disconnect();
  console.log("Seeding complete!");
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
