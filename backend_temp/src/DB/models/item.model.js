import mongoose, { Types } from "mongoose";

// Define schema for Item
const schema = new mongoose.Schema(
  {
    user: { 
      type: Types.ObjectId,
      ref: "User",
      required: true,
      index: true
    },
    name: { 
      type: String,
      required: true,
      trim: true
    },
    price: { 
      type: Number,
      default: 0
    },
    category: {
      type: Types.ObjectId,
      ref: "Category",
      index: true
    },
    description: {
      type: String,
      trim: true
    },
    isActive: {
      type: Boolean,
      default: true
    }
  },
  { 
    timestamps: true,
    versionKey: false
  }
);

// Index for searching items
schema.index({ user: 1, name: 1 });
schema.index({ name: 'text' });

// Create and export the Item model
export const Item = mongoose.model("Item", schema);
