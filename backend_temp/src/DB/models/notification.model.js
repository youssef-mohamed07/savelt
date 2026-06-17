import mongoose, { Types } from "mongoose";

const schema = new mongoose.Schema(
  {
    user: {
      type: Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    body: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ["transaction", "reminder", "offer", "system"],
      default: "system",
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    referenceId: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

schema.index({ user: 1, createdAt: -1 });
schema.index({ user: 1, isRead: 1 });

schema.statics.findForUser = function (userId, limit = 50) {
  return this.find({ user: userId }).sort({ createdAt: -1 }).limit(limit);
};

export const Notification = mongoose.model("Notification", schema);
