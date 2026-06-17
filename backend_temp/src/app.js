/**
 * Express Application Setup
 * Separated from server for better testing and modularity
 */
import express from 'express';
import cors from 'cors';
import { config } from './config/index.js';

// Middleware
import { sanitizeInput, preventNoSQLInjection } from './middleware/sanitize.js';
import { apiLimiter } from './middleware/rateLimiter.js';

// Error handlers
import { GlobalError } from './utils/GlobalError.js';
import { URL_Error } from './utils/URL_Catch.js';

// Routes
import { bootstrap } from './module/bootStrap.js';
import { ensureUploadDirs } from './middleware/upload.js';

export function createApp() {
  const app = express();

  ensureUploadDirs();

  // Security & CORS
  app.use(cors({
    origin: config.corsOrigin,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization', 'token']
  }));

  // Rate limiting
  app.use(apiLimiter);

  // Body parsing
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Input sanitization
  app.use(sanitizeInput);
  app.use(preventNoSQLInjection);

  // Static files
  app.use('/uploads', express.static('src/uploads'));
  app.use('/arrayFiles', express.static('arrayFiles'));
  app.use('/ShuffleFiles', express.static('ShuffleFiles'));

  // Health check endpoint (required for DigitalOcean)
  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
  });

  // API root
  app.get('/api', (req, res) => {
    res.json({ message: 'Server is running!', version: '1.0.0' });
  });

  // DB debug — shows which database and collections are active
  app.get('/debug/db', async (req, res) => {
    try {
      const mongoose = await import('mongoose');
      const conn = mongoose.default.connection;
      const collections = await conn.db.listCollections().toArray();
      const counts = {};
      for (const col of collections) {
        counts[col.name] = await conn.db.collection(col.name).countDocuments();
      }
      res.json({
        database: conn.db.databaseName,
        host: conn.host,
        collections: counts,
      });
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });

  // Clear offers cache (for testing) — ES modules version
  app.get('/debug/clear-offers-cache', async (req, res) => {
    try {
      const { offersCache } = await import('./module/offers/offer.service.js');
      offersCache.flushAll();
      res.json({ success: true, message: 'Offers cache cleared' });
    } catch (e) {
      res.json({ success: false, message: e.message });
    }
  });

  // Mount routes
  bootstrap(app);

  // 404 handler
  app.use(URL_Error);

  // Global error handler
  app.use(GlobalError);

  return app;
}
