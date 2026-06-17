/**
 * MongoDB connection via Mongoose ORM (single database for the app).
 */
import mongoose from 'mongoose';
import { config } from './index.js';

let isConnected = false;

export async function connectDatabase() {
  if (isConnected) {
    console.log('[DB] Using existing MongoDB connection');
    return mongoose.connection;
  }

  if (!config.mongoUri) {
    console.error('[DB] MONGO_URI is missing');
    process.exit(1);
  }

  try {
    const conn = await mongoose.connect(config.mongoUri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      dbName: config.mongoDbName,
    });

    isConnected = true;
    console.log(
      `[DB] ✅ MongoDB (Mongoose) → ${conn.connection.host} | db: ${conn.connection.db.databaseName}`,
    );

    mongoose.connection.on('error', (err) => {
      console.error('[DB] MongoDB error:', err.message);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('[DB] MongoDB disconnected');
      isConnected = false;
    });

    return conn.connection;
  } catch (error) {
    console.error('[DB] MongoDB connection failed:', error.message);
    process.exit(1);
  }
}

export async function disconnectDatabase() {
  if (!isConnected) return;
  await mongoose.connection.close();
  isConnected = false;
  console.log('[DB] MongoDB connection closed');
}

export function getConnection() {
  return mongoose.connection;
}
