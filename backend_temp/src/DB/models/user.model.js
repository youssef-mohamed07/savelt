import mongoose from "mongoose";

// User schema definition
const schema = new mongoose.Schema(
  {
    fullname: { type: String, trim: true },

    firstName: { type: String, trim: true },

    lastName: { type: String, trim: true },

    email: { type: String, trim: true, unique: true, lowercase: true, index: true },

    password: { type: String },

    phone: { type: String },

    confEmail: { type: Boolean, default: false },

    isBlocked: { type: Boolean, default: false },

    isDeleted: { type: Boolean, default: false },

    role: { type: String, enum: ['customer', 'admin'], default: 'customer' },

    OTP: { type: String, match: [/^\d{4,6}$/, "OTP must be a 4 to 6 digit number"], default: null },

    googleId: { type: String, default: null, sparse: true, unique: true },

    authProvider: { type: String, enum: ['local', 'google'], default: 'local' },

    resetOTP: { type: String, match: [/^\d{4,6}$/, "Reset OTP must be a 4 to 6 digit number"], default: null },

    resetOTPExpiresAt: { type: Date, default: null },

    passwordChangedAt: { type: Date },

    avatar: { type: String },

    preferences: {
      currency: { type: String, default: 'EGP' },
      language: { type: String, default: 'ar' },
      notifications: { type: Boolean, default: true }
    }
  },
 { timestamps: true, versionKey: false }
);

// Indexes
schema.index({ createdAt: -1 });
schema.index({ isDeleted: 1, confEmail: 1 });

schema.statics.findActiveByEmail = function (email) {
  return this.findOne({
    email: email.toLowerCase().trim(),
    isDeleted: { $ne: true },
  });
};

// Export User model
export const User = mongoose.model("User", schema);
