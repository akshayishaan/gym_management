import mongoose, { Schema, Document, Model } from "mongoose";

export interface IGym extends Document {
  name: string;
  logo?: string;
  primaryColor: string;
  address?: string;
  phone?: string;
  email?: string;
  currency: string;
  expiryReminderDays: number;
  isActive: boolean;
  ownerId?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const GymSchema = new Schema<IGym>(
  {
    name: { type: String, required: true, trim: true },
    logo: { type: String },
    primaryColor: { type: String, default: "#6366f1" },
    address: { type: String },
    phone: { type: String },
    email: { type: String },
    currency: { type: String, default: "INR" },
    expiryReminderDays: { type: Number, default: 7 },
    isActive: { type: Boolean, default: true },
    ownerId: { type: Schema.Types.ObjectId, ref: "Staff", index: true },
  },
  { timestamps: true }
);

const Gym: Model<IGym> =
  mongoose.models.Gym || mongoose.model<IGym>("Gym", GymSchema);

export default Gym;
