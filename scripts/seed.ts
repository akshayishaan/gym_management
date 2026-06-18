import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017/gym_management";
const ADMIN_EMAIL = process.env.SEED_ADMIN_EMAIL || "admin@gym.com";
const ADMIN_PASSWORD = process.env.SEED_ADMIN_PASSWORD || "admin123";
const GYM_NAME = process.env.SEED_GYM_NAME || "My Gym";
const SUPERADMIN_EMAIL = process.env.SEED_SUPERADMIN_EMAIL || "superadmin@platform.com";
const SUPERADMIN_PASSWORD = process.env.SEED_SUPERADMIN_PASSWORD || "superadmin123";

async function seed() {
  await mongoose.connect(MONGODB_URI);
  console.log("Connected to MongoDB");

  const db = mongoose.connection.db!;

  // Seed superadmin (no gymId)
  const existingSuperAdmin = await db.collection("staffs").findOne({ email: SUPERADMIN_EMAIL });
  if (!existingSuperAdmin) {
    const hashed = await bcrypt.hash(SUPERADMIN_PASSWORD, 12);
    await db.collection("staffs").insertOne({
      name: "Super Admin",
      email: SUPERADMIN_EMAIL,
      password: hashed,
      role: "superadmin",
      gymId: null,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    console.log(`Superadmin created: ${SUPERADMIN_EMAIL} / ${SUPERADMIN_PASSWORD}`);
  } else {
    console.log("Superadmin already exists, skipping.");
  }

  // Seed a default gym + admin
  const existing = await db.collection("staffs").findOne({ email: ADMIN_EMAIL });
  if (!existing) {
    // Create gym
    const gymResult = await db.collection("gyms").insertOne({
      name: GYM_NAME,
      primaryColor: "#6366f1",
      currency: "INR",
      expiryReminderDays: 7,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    const gymId = gymResult.insertedId;
    console.log(`Default gym created: ${GYM_NAME} (${gymId})`);

    // Create gym admin
    const hashed = await bcrypt.hash(ADMIN_PASSWORD, 12);
    await db.collection("staffs").insertOne({
      name: "Admin",
      email: ADMIN_EMAIL,
      password: hashed,
      role: "admin",
      gymId,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    console.log(`Gym admin created: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);

    // Seed sample plans for this gym
    await db.collection("plans").insertMany([
      {
        gymId,
        name: "Monthly",
        description: "1 month membership",
        durationDays: 30,
        price: 1500,
        features: ["Full gym access", "Locker room"],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        gymId,
        name: "Quarterly",
        description: "3 month membership",
        durationDays: 90,
        price: 4000,
        features: ["Full gym access", "Locker room", "1 PT session"],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        gymId,
        name: "Annual",
        description: "12 month membership",
        durationDays: 365,
        price: 12000,
        features: ["Full gym access", "Locker room", "4 PT sessions", "Diet plan"],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ]);
    console.log("Sample plans created.");
  } else {
    console.log("Gym admin already exists, skipping.");
  }

  await mongoose.disconnect();
  console.log("Seeding complete!");
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
