import mongoose, { Schema, Document, Model } from "mongoose";

export interface IMembership extends Document {
  gymId: mongoose.Types.ObjectId;
  memberId: mongoose.Types.ObjectId;
  planId?: mongoose.Types.ObjectId;
  planName: string;       // immutable snapshot — see docs/denormalization-strategy.md
  startDate: string;
  expiryDate: string;
  paymentId?: mongoose.Types.ObjectId;  // link to the Payment that created this record
  planPrice?: number;     // immutable snapshot of the plan's price at purchase time
  amount?: number;        // immutable snapshot of amount paid
  grantedBy: mongoose.Types.ObjectId;   // Staff who recorded the payment
  notes?: string;
  status: "active" | "reversed";
  reversedAt?: Date;
  reversedBy?: mongoose.Types.ObjectId;
  reversalReason?: string;
  createdAt: Date;
  updatedAt: Date;
}

const MembershipSchema = new Schema<IMembership>(
  {
    gymId:     { type: Schema.Types.ObjectId, ref: "Gym",     required: true, index: true },
    memberId:  { type: Schema.Types.ObjectId, ref: "Member",  required: true },
    planId:    { type: Schema.Types.ObjectId, ref: "Plan" },
    planName:  { type: String, required: true },
    startDate: { type: String, required: true },
    expiryDate:{ type: String, required: true },
    paymentId: { type: Schema.Types.ObjectId, ref: "Payment" },
    planPrice: { type: Number },
    amount:    { type: Number },
    grantedBy: { type: Schema.Types.ObjectId, ref: "Staff", required: true },
    notes:     { type: String },
    status:    { type: String, enum: ["active", "reversed"], default: "active" },
    reversedAt:{ type: Date },
    reversedBy:{ type: Schema.Types.ObjectId, ref: "Staff" },
    reversalReason: { type: String },
  },
  { timestamps: true }
);

// Primary query pattern: all memberships for a member, newest first
MembershipSchema.index({ gymId: 1, memberId: 1, expiryDate: -1 });
// Supports renewal reporting, which partitions a gym's history by member and purchase time.
MembershipSchema.index({ gymId: 1, memberId: 1, createdAt: 1 });
// Future use: expiring-soon queries across the gym
MembershipSchema.index({ gymId: 1, expiryDate: 1 });
MembershipSchema.index({ gymId: 1, memberId: 1, status: 1, createdAt: -1 });
MembershipSchema.index({ gymId: 1, planId: 1, status: 1, createdAt: -1 });

const Membership: Model<IMembership> =
  mongoose.models.Membership || mongoose.model<IMembership>("Membership", MembershipSchema);

export default Membership;
