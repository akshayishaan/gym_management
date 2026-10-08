import mongoose, { Schema, Document, Model } from "mongoose";

export interface IActivityLog extends Document {
  gymId?: mongoose.Types.ObjectId;
  staffId?: mongoose.Types.ObjectId;
  staffName: string;
  action: string;
  entity: string;
  entityId?: string;
  details?: string;
  createdAt: Date;
}

const ActivityLogSchema = new Schema<IActivityLog>(
  {
    gymId: { type: Schema.Types.ObjectId, ref: "Gym", index: true },
    staffId: { type: Schema.Types.ObjectId, ref: "Staff" },
    staffName: { type: String, required: true },
    action: { type: String, required: true },
    entity: { type: String, required: true },
    entityId: { type: String },
    details: { type: String },
  },
  { timestamps: true },
);

const ActivityLog: Model<IActivityLog> =
  mongoose.models.ActivityLog ||
  mongoose.model<IActivityLog>("ActivityLog", ActivityLogSchema);

export default ActivityLog;
