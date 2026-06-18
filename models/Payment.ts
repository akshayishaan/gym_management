import mongoose, { Schema, Document, Model } from "mongoose";

export interface IPayment extends Document {
  gymId: mongoose.Types.ObjectId;
  memberId: mongoose.Types.ObjectId;
  memberName: string;
  planId?: mongoose.Types.ObjectId;
  planName?: string;
  amount: number;
  method: "cash" | "card" | "upi" | "bank_transfer" | "other";
  status: "paid" | "pending" | "refunded";
  invoiceNumber: string;
  notes?: string;
  paidAt: Date;
  createdBy?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const PaymentSchema = new Schema<IPayment>(
  {
    gymId: { type: Schema.Types.ObjectId, ref: "Gym", required: true, index: true },
    memberId: { type: Schema.Types.ObjectId, ref: "Member", required: true },
    memberName: { type: String, required: true },
    planId: { type: Schema.Types.ObjectId, ref: "Plan" },
    planName: { type: String },
    amount: { type: Number, required: true },
    method: {
      type: String,
      enum: ["cash", "card", "upi", "bank_transfer", "other"],
      default: "cash",
    },
    status: {
      type: String,
      enum: ["paid", "pending", "refunded"],
      default: "paid",
    },
    invoiceNumber: { type: String, required: true, unique: true },
    notes: { type: String },
    paidAt: { type: Date, default: Date.now },
    createdBy: { type: Schema.Types.ObjectId, ref: "Staff" },
  },
  { timestamps: true }
);

// Compound indexes for common query patterns
PaymentSchema.index({ gymId: 1, status: 1, paidAt: -1 });
PaymentSchema.index({ gymId: 1, memberId: 1 });
PaymentSchema.index({ gymId: 1, createdAt: -1 });

const Payment: Model<IPayment> =
  mongoose.models.Payment || mongoose.model<IPayment>("Payment", PaymentSchema);

export default Payment;
