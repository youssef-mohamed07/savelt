import mongoose, { Types } from "mongoose";

const schema = new mongoose.Schema(
  {
    user: {
      type: Types.ObjectId,
      ref: "User",
      required: [true, "user is required"],
      index: true,
    },

    category: {
      type: Types.ObjectId,
      ref: "Category",
      index: true,
    },

    items: {
      type: [Types.ObjectId],
      ref: "Item",
      default: [],
    },

    price: {
      type: Number,
      default: 0,
      min: 0,
    },

    text: {
      type: String,
      trim: true,
    },

    quantity: {
      type: Number,
      default: 1,
      min: 1,
    },

    OCR_path: {
      type: String,
    },

    voice_path: {
      type: String,
    },

    type: {
      type: String,
      enum: ["expense", "income"],
      default: "expense",
    },

    notes: {
      type: String,
      trim: true,
    },

    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },

    transactionDate: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

// ── Indexes (analytics, lists, export) ───────────────────────────────────────
schema.index({ user: 1, createdAt: -1 });
schema.index({ user: 1, category: 1 });
schema.index({ user: 1, isDeleted: 1, createdAt: -1 });
schema.index({ user: 1, transactionDate: -1 });
schema.index({ user: 1, type: 1, createdAt: -1 });

// ── ORM helpers ──────────────────────────────────────────────────────────────
schema.statics.findActiveForUser = function (userId, extraFilter = {}) {
  return this.find({
    user: userId,
    isDeleted: { $ne: true },
    ...extraFilter,
  });
};

schema.statics.softDeleteForUser = function (userId, transactionId) {
  return this.findOneAndUpdate(
    { _id: transactionId, user: userId, isDeleted: { $ne: true } },
    { isDeleted: true },
    { new: true },
  );
};

schema.methods.effectiveDate = function () {
  return this.transactionDate || this.createdAt;
};

export const Transactions = mongoose.model("Transactions", schema);
