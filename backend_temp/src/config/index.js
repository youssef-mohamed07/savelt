/**
 * Centralized Configuration Module
 */
import dotenv from 'dotenv';
dotenv.config();

export const config = {
  // Server
  port: parseInt(process.env.PORT, 10) || 3001,
  nodeEnv: process.env.NODE_ENV || 'development',

  // MongoDB (Mongoose ORM — sole database)
  mongoUri: process.env.MONGO_URI,
  mongoDbName: process.env.MONGO_DB_NAME || 'test',

  // JWT
  jwtKey: process.env.JWT_KEY,
  jwtExpiry: process.env.JWT_EXPIRY || '7d',

  // CORS
  corsOrigin: process.env.CORS_ORIGIN || '*',

  // WebSocket
  wsPort: parseInt(process.env.WS_PORT, 10) || 3002,
  wsUrl: process.env.WS_URL || 'ws://localhost:3002',

  // Email
  email: {
    service: process.env.EMAIL_SERVICE || 'gmail',
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },

  // URLs
  baseUrl: process.env.BASE_URL || 'http://localhost:3001/uploads/',
  domainUrl: process.env.DOMAIN_URL || 'http://localhost:3000',
};

export function validateConfig() {
  const required = ['mongoUri', 'jwtKey'];
  const missing = required.filter((key) => !config[key]);

  if (missing.length > 0) {
    console.error(`[CONFIG] Missing required env vars: ${missing.join(', ')}`);
    process.exit(1);
  }

  console.log('[CONFIG] Configuration validated (MongoDB only)');
  return true;
};
