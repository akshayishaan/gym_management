import mongoose, { Schema, Document, Model } from "mongoose";

export interface IPlan extends Document {
  gymId: mongoose.Types.ObjectId;
  name: string;
  description?: string;
  durationDays: number;
  price: number;
  features?: string[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const PlanSchema = new Schema<IPlan>(
  {
    gymId: { type: Schema.Types.ObjectId, ref: "Gym", required: true, index: true },
    name: { type: String, required: true, trim: true },
    description: { type: String },
    durationDays: { type: Number, required: true },
    price: { type: Number, required: true },
    features: [{ type: String }],
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

PlanSchema.index({ gymId: 1, price: 1 });

const Plan: Model<IPlan> =
  mongoose.models.Plan || mongoose.model<IPlan>("Plan", PlanSchema);

export default Plan;
