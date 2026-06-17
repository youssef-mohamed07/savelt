/**
 * Centralized Configuration Module
 * All environment variables and app settings in one place
 */
import dotenv from 'dotenv';
dotenv.config();

export const config = {
  // Server
  port: parseInt(process.env.PORT, 10) || 3001,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Database
  mongoUri: process.env.MONGO_URI,
  databaseUrl: process.env.DATABASE_URL,
  directUrl: process.env.DIRECT_URL,
  dbProvider: process.env.DB_PROVIDER || 'mongo', // 'mongo' | 'postgres'
  
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
    pass: process.env.EMAIL_PASS
  },
  
  // URLs
  baseUrl: process.env.BASE_URL || 'http://localhost:3001/uploads/',
  domainUrl: process.env.DOMAIN_URL || 'http://localhost:3000'
};

// Validate required config
export function validateConfig() {
  const required = config.dbProvider === 'postgres'
    ? ['databaseUrl', 'jwtKey']
    : ['mongoUri', 'jwtKey'];
  const missing = required.filter(key => !config[key]);
  
  if (missing.length > 0) {
    console.error(`[CONFIG] Missing required env vars: ${missing.join(', ')}`);
    process.exit(1);
  }
  
  console.log('[CONFIG] Configuration validated successfully');
  return true;
}
