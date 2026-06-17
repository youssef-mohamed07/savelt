/**
 * Legacy Database Connection
 * Use src/config/database.js for new implementations
 */
import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error("[DB] ❌ MONGO_URI missing from .env");
  process.exit(1);
}

// Ensure database name is in the URI
const uriWithDb = MONGO_URI.includes('/test')
  ? MONGO_URI
  : MONGO_URI.replace('/?', '/test?').replace(/\/$/, '/test');

console.log(`[DB] Connecting to MongoDB...`);

export const dbConnection = mongoose.connect(uriWithDb, {
  family: 4,
  serverSelectionTimeoutMS: 15000,
  dbName: 'test',
})
  .then(() => {
    console.log(`[DB] ✅ Connected to database: ${mongoose.connection.db.databaseName}`);
  })
  .catch((error) => {
    console.error("[DB] ❌ Connection error:", error.message);
    process.exit(1);
  });


  