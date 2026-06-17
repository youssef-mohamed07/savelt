import mongoose, { Types } from "mongoose";

// Define schema for Transactions 
const schema = new mongoose.Schema(
  {
    user: { 
      type: Types.ObjectId,
      ref: "User",
      required: [true, "user is required"],
      index: true
    },

    category: { 
      type: Types.ObjectId,
      ref: "Category",
      index: true
    },

    price: { 
      type: Number,
      default: 0
    },

    text: { 
      type: String,
      trim: true
    },

    quantity: {
      type: Number,
      default: 1,
      min: 1
    },

    OCR_path: { 
      type: String
    },
    
    voice_path: { 
      type: String
    },

    type: {
      type: String,
      enum: ['expense', 'income'],
      default: 'expense'
    },

    notes: {
      type: String,
      trim: true
    },

    isDeleted: {
      type: Boolean,
      default: false
    },

    transactionDate: {
      type: Date,
      default: null  // if null, fall back to createdAt
    }
  },
  { 
    timestamps: true,
    versionKey: false
  }
);

// Indexes
schema.index({ user: 1, createdAt: -1 });
schema.index({ user: 1, category: 1 });
schema.index({ createdAt: -1 });

// Create and export the Transactions model
export const Transactions = mongoose.model("Transactions", schema);


