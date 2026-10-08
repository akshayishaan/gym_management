import mongoose, { Schema, Document, Model } from "mongoose";

export interface IPayment extends Document {
  gymId: mongoose.Types.ObjectId;
  memberId: mongoose.Types.ObjectId;
  memberName: string;
  planId?: mongoose.Types.ObjectId;
  planName?: string;
  /** Snapshot of the Plan's `features` at purchase time (plan_purchase only),
   *  so an invoice keeps showing what the member actually got even if the
   *  Plan's features are edited or removed later. */
  planFeatures?: string[];
  /** Snapshot of the Plan's `durationDays` at purchase time (plan_purchase
   *  only), so the invoice's billing-cycle label is always real. */
  planDurationDays?: number;
  amount: number;
  kind: "plan_purchase" | "dues";
  method: "cash" | "card" | "upi" | "bank_transfer" | "other";
  status: "paid" | "voided" | "refunded";
  invoiceNumber: string;
  /** Optional staff-entered reference for non-cash methods (UPI transaction
   *  ID, card auth code, cheque number, bank transfer ref, etc.). Never
   *  fabricated client-side — absent when the staff didn't provide one. */
  reference?: string;
  notes?: string;
  paidAt: Date;
  createdBy?: mongoose.Types.ObjectId;
  voidedAt?: Date;
  voidedBy?: mongoose.Types.ObjectId;
  voidReason?: string;
  refundedAt?: Date;
  refundedBy?: mongoose.Types.ObjectId;
  refundReason?: string;
  createdAt: Date;
  updatedAt: Date;
}

const PaymentSchema = new Schema<IPayment>(
  {
    gymId: {
      type: Schema.Types.ObjectId,
      ref: "Gym",
      required: true,
      index: true,
    },
    memberId: { type: Schema.Types.ObjectId, ref: "Member", required: true },
    memberName: { type: String, required: true },
    planId: { type: Schema.Types.ObjectId, ref: "Plan" },
    planName: { type: String },
    planFeatures: [{ type: String }],
    planDurationDays: { type: Number },
    amount: { type: Number, required: true },
    kind: {
      type: String,
      enum: ["plan_purchase", "dues"],
      required: true,
    },
    method: {
      type: String,
      enum: ["cash", "card", "upi", "bank_transfer", "other"],
      default: "cash",
    },
    status: {
      type: String,
      enum: ["paid", "voided", "refunded"],
      default: "paid",
    },
    invoiceNumber: { type: String, required: true, unique: true },
    reference: { type: String },
    notes: { type: String },
    paidAt: { type: Date, default: Date.now },
    createdBy: { type: Schema.Types.ObjectId, ref: "Staff" },
    voidedAt: { type: Date },
    voidedBy: { type: Schema.Types.ObjectId, ref: "Staff" },
    voidReason: { type: String },
    refundedAt: { type: Date },
    refundedBy: { type: Schema.Types.ObjectId, ref: "Staff" },
    refundReason: { type: String },
  },
  { timestamps: true },
);

// Compound indexes for common query patterns
PaymentSchema.index({ gymId: 1, status: 1, paidAt: -1 });
PaymentSchema.index({ gymId: 1, memberId: 1 });
PaymentSchema.index({ gymId: 1, createdAt: -1 });
PaymentSchema.index({ gymId: 1, status: 1, paidAt: -1, planId: 1 });
PaymentSchema.index({ gymId: 1, status: 1, refundedAt: -1, planId: 1 });

const Payment: Model<IPayment> =
  mongoose.models.Payment || mongoose.model<IPayment>("Payment", PaymentSchema);

export default Payment;
