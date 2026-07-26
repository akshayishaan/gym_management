import mongoose, { Schema, Document, Model } from "mongoose";

export interface IMember extends Document {
  gymId: mongoose.Types.ObjectId;
  name: string;
  email?: string;
  phone: string;
  address?: string;
  photo?: string;
  dateOfBirth?: Date;
  gender?: "male" | "female" | "other";
  planId?: mongoose.Types.ObjectId;
  planName?: string;
  membershipStart?: string;
  membershipExpiry?: string;
  notes?: string;
  emergencyContact?: string;
  dueAmount: number;    // cached ledger balance: sum(plan prices) - sum(payments)
  isActive: boolean;    // soft-delete flag; "deleting" a member sets this false
  createdAt: Date;
  updatedAt: Date;
}

const MemberSchema = new Schema<IMember>(
  {
    gymId: { type: Schema.Types.ObjectId, ref: "Gym", required: true, index: true },
    name: { type: String, required: true, trim: true },
    email: { type: String, trim: true, lowercase: true },
    phone: { type: String, required: true, trim: true },
    address: { type: String, trim: true },
    photo: { type: String },
    dateOfBirth: { type: Date },
    gender: { type: String, enum: ["male", "female", "other"] },
    planId: { type: Schema.Types.ObjectId, ref: "Plan" },
    planName: { type: String },
    membershipStart: { type: String },
    membershipExpiry: { type: String },
    notes: { type: String },
    emergencyContact: { type: String },
    dueAmount: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// Compound indexes for common query patterns
MemberSchema.index({ gymId: 1, membershipExpiry: 1 });
MemberSchema.index({ gymId: 1, planName: 1 });
MemberSchema.index({ gymId: 1, createdAt: -1 });
MemberSchema.index({ gymId: 1, isActive: 1, membershipExpiry: 1, planId: 1 });

const Member: Model<IMember> =
  mongoose.models.Member || mongoose.model<IMember>("Member", MemberSchema);

export default Member;
