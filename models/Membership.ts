import mongoose, { Schema, Document, Model } from "mongoose";

export interface IMembership extends Document {
  gymId: mongoose.Types.ObjectId;
  memberId: mongoose.Types.ObjectId;
  planId?: mongoose.Types.ObjectId;
  planName: string;       // immutable snapshot — see docs/denormalization-strategy.md
  startDate: Date;
  expiryDate: Date;
  paymentId?: mongoose.Types.ObjectId;  // link to the Payment that created this record
  planPrice?: number;     // immutable snapshot of the plan's price at purchase time
  amount?: number;        // immutable snapshot of amount paid
  grantedBy: mongoose.Types.ObjectId;   // Staff who recorded the payment
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const MembershipSchema = new Schema<IMembership>(
  {
    gymId:     { type: Schema.Types.ObjectId, ref: "Gym",     required: true, index: true },
    memberId:  { type: Schema.Types.ObjectId, ref: "Member",  required: true },
    planId:    { type: Schema.Types.ObjectId, ref: "Plan" },
    planName:  { type: String, required: true },
    startDate: { type: Date, required: true },
    expiryDate:{ type: Date, required: true },
    paymentId: { type: Schema.Types.ObjectId, ref: "Payment" },
    planPrice: { type: Number },
    amount:    { type: Number },
    grantedBy: { type: Schema.Types.ObjectId, ref: "Staff", required: true },
    notes:     { type: String },
  },
  { timestamps: true }
);

// Primary query pattern: all memberships for a member, newest first
MembershipSchema.index({ gymId: 1, memberId: 1, expiryDate: -1 });
// Future use: expiring-soon queries across the gym
MembershipSchema.index({ gymId: 1, expiryDate: 1 });

const Membership: Model<IMembership> =
  mongoose.models.Membership || mongoose.model<IMembership>("Membership", MembershipSchema);

export default Membership;
