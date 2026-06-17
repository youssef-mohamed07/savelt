import mongoose, { Types } from "mongoose";

// Define schema for Category
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
    items: { 
      type: [Types.ObjectId],
      ref: "Item",
      default: []
    },
    color: { 
      type: String,
      default: "#ffffff"
    },
    icon: {
      type: String,
      default: "category"
    },
    budget: {
      type: Number,
      default: 0
    },
    isDefault: {
      type: Boolean,
      default: false
    }
  },
  { 
    timestamps: true,
    versionKey: false
  }
);

// Compound index for unique category name per user
schema.index({ user: 1, name: 1 }, { unique: true });

// Create and export the Category model
export const Category = mongoose.model("Category", schema);
