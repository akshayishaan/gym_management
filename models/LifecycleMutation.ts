import mongoose, { Schema, type Model } from "mongoose";

export type LifecycleOperation =
  | "member_onboarding"
  | "record_payment"
  | "void_payment"
  | "refund_payment"
  | "reverse_plan_purchase";

export interface ILifecycleMutation {
  gymId: mongoose.Types.ObjectId;
  requestId: string;
  operation: LifecycleOperation;
  result: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

const LifecycleMutationSchema = new Schema<ILifecycleMutation>(
  {
    gymId: { type: Schema.Types.ObjectId, ref: "Gym", required: true },
    requestId: { type: String, required: true },
    operation: {
      type: String,
      enum: [
        "member_onboarding",
        "record_payment",
        "void_payment",
        "refund_payment",
        "reverse_plan_purchase",
      ],
      required: true,
    },
    result: { type: Schema.Types.Mixed, required: true },
  },
  { timestamps: true }
);

LifecycleMutationSchema.index({ gymId: 1, requestId: 1 }, { unique: true });

const LifecycleMutation: Model<ILifecycleMutation> =
  mongoose.models.LifecycleMutation
  || mongoose.model<ILifecycleMutation>("LifecycleMutation", LifecycleMutationSchema);

export default LifecycleMutation;
