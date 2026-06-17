import mongoose, { Types } from "mongoose";

const schema = new mongoose.Schema(
  {
    user: {
      type: Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    title: { type: String, required: true, trim: true },
    amount: { type: Number, default: null },
    date: { type: Date, required: true },
    repeat: {
      type: String,
      enum: ["Once", "Daily", "Weekly", "Monthly", "Yearly"],
      default: "Once",
    },
    enabled: { type: Boolean, default: true },
    iconCode: { type: Number, default: 0xe7f4 }, // notifications_rounded
    sound: {
      type: String,
      enum: ["defaultSound", "alarm1", "alarm2", "gentle", "silent"],
      default: "defaultSound",
    },
  },
  { timestamps: true, versionKey: false }
);

schema.index({ user: 1, date: 1 });
schema.index({ user: 1, enabled: 1, date: 1 });

schema.statics.findUpcomingForUser = function (userId) {
  return this.find({ user: userId, enabled: true, date: { $gte: new Date() } }).sort({
    date: 1,
  });
};

export const Reminder = mongoose.model("Reminder", schema);
