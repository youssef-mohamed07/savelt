/**
 * Database Connection Module
 * MongoDB (default) or Supabase Postgres via DB_PROVIDER
 */
import mongoose from 'mongoose';
import { config } from './index.js';
import { connectPostgres, disconnectPostgres } from './postgres.js';

let isConnected = false;

export async function connectDatabase() {
  if (isConnected) {
    console.log('[DB] Using existing connection');
    return;
  }

  if (config.dbProvider === 'postgres') {
    await connectPostgres();
    isConnected = true;
    return;
  }

  if (!config.mongoUri) {
    console.error('[DB] MONGO_URI is missing');
    process.exit(1);
  }

  try {
    const conn = await mongoose.connect(config.mongoUri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 30000,  // 30s — Atlas can be slow on first connect
      socketTimeoutMS: 45000,
      dbName: 'test',                   // always use 'test' database
    });
    
    isConnected = true;
    console.log(`[DB] ✅ Connected to MongoDB: ${conn.connection.host} | db: ${conn.connection.db.databaseName}`);
    
    // Handle connection events
    mongoose.connection.on('error', (err) => {
      console.error('[DB] Connection error:', err.message);
    });
    
    mongoose.connection.on('disconnected', () => {
      console.log('[DB] Disconnected from MongoDB');
      isConnected = false;
    });
    
  } catch (error) {
    console.error('[DB] Connection failed:', error.message);
    process.exit(1);
  }
}

export async function disconnectDatabase() {
  if (!isConnected) return;

  if (config.dbProvider === 'postgres') {
    await disconnectPostgres();
  } else {
    await mongoose.connection.close();
  }
  isConnected = false;
  console.log('[DB] Connection closed');
}
