/**
 * Migration script: Convert Staff.gymId (single) → Staff.gymIds (array)
 * and add Gym.ownerId to each gym.
 *
 * Run with: npx tsx scripts/migrate-multi-tenant.ts
 *
 * Make sure MONGODB_URI is set in your .env file.
 */

import mongoose from "mongoose";

const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017/gym_management";

async function migrate() {
  console.log("Connecting to MongoDB...");
  await mongoose.connect(MONGODB_URI);
  console.log("Connected.");

  const db = mongoose.connection.db!;

  // Step 1: Migrate Staff.gymId → Staff.gymIds
  console.log("\n--- Migrating Staff.gymId → Staff.gymIds ---");

  const staffCollection = db.collection("staffs");
  const staffWithGymId = await staffCollection.find({ gymId: { $exists: true, $ne: null } }).toArray();
  console.log(`Found ${staffWithGymId.length} staff documents with gymId field.`);

  let staffMigrated = 0;
  for (const staff of staffWithGymId) {
    const gymId = staff.gymId;
    if (gymId) {
      await staffCollection.updateOne(
        { _id: staff._id },
        {
          $push: { gymIds: gymId },
          $unset: { gymId: "" },
        }
      );
      staffMigrated++;
    }
  }
  console.log(`Migrated ${staffMigrated} staff documents.`);

  // Handle staff with gymId: null (superadmins) — just unset the field
  const staffWithNullGymId = await staffCollection.find({ gymId: null }).toArray();
  if (staffWithNullGymId.length > 0) {
    await staffCollection.updateMany(
      { gymId: null },
      { $unset: { gymId: "" } }
    );
    console.log(`Cleaned up gymId:null from ${staffWithNullGymId.length} staff documents.`);
  }

  // Ensure all staff have gymIds field
  await staffCollection.updateMany(
    { gymIds: { $exists: false } },
    { $set: { gymIds: [] } }
  );
  console.log("Ensured all staff documents have gymIds field.");

  // Step 2: Add Gym.ownerId
  console.log("\n--- Adding Gym.ownerId ---");

  const gymCollection = db.collection("gyms");
  const gyms = await gymCollection.find({}).toArray();
  console.log(`Found ${gyms.length} gym documents.`);

  let gymsUpdated = 0;
  for (const gym of gyms) {
    if (!gym.ownerId) {
      // Find the first admin staff with this gym in their gymIds
      const admin = await staffCollection.findOne({
        gymIds: gym._id,
        role: "admin",
        isActive: true,
      });

      if (admin) {
        await gymCollection.updateOne(
          { _id: gym._id },
          { $set: { ownerId: admin._id } }
        );
        gymsUpdated++;
      } else {
        console.log(`  Warning: No admin found for gym "${gym.name}" (${gym._id})`);
      }
    }
  }
  console.log(`Set ownerId on ${gymsUpdated} gym documents.`);

  // Step 3: Verification
  console.log("\n--- Verification ---");

  const remainingGymId = await staffCollection.countDocuments({ gymId: { $exists: true } });
  const staffWithGymIds = await staffCollection.countDocuments({ gymIds: { $exists: true } });
  const totalStaff = await staffCollection.countDocuments({});

  console.log(`Total staff: ${totalStaff}`);
  console.log(`Staff with gymIds: ${staffWithGymIds}`);
  console.log(`Staff still with old gymId: ${remainingGymId}`);

  if (remainingGymId > 0) {
    console.log("⚠️  Some staff still have the old gymId field. Manual cleanup may be needed.");
  } else {
    console.log("✅ All staff migrated successfully.");
  }

  await mongoose.disconnect();
  console.log("\nMigration complete. Disconnected from MongoDB.");
}

migrate().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
