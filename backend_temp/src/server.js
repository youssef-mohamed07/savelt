/**
 * Server Entry Point
 * Handles HTTP server and WebSocket initialization
 */
import http from 'http';
import { config, validateConfig } from './config/index.js';
import { connectDatabase } from './config/database.js';
import { createApp } from './app.js';
import { startWsServer } from './module/analysis/wsServer.js';
import { startAiService, stopAiService } from './services/aiService.js';
import { warmOffersCache } from './module/offers/offer.service.js';
import { handleRuntimeError, handleErrorCode } from './utils/outError.js';

// Enable logging
import './utils/logger.js';

async function startServer() {
  // Validate configuration
  validateConfig();
  
  // Connect to database
  await connectDatabase();

  const app = createApp();
  const server = http.createServer(app);

  server.listen(config.port, '0.0.0.0', () => {
    console.log(`[SERVER] HTTP server running on port ${config.port}`);
    console.log(`[SERVER] Environment: ${config.nodeEnv}`);
    warmOffersCache();
  });

  if (config.nodeEnv !== 'test') {
    startWsServer({ port: config.wsPort });
  }

  // AI starts in background — HTTP + WS are ready immediately
  startAiService().catch((err) => {
    console.error('[AI] Failed to start:', err.message || err);
  });
  
  // Graceful shutdown
  const shutdown = async (signal) => {
    console.log(`[SERVER] ${signal} received, shutting down gracefully`);
    stopAiService();
    server.close(() => {
      console.log('[SERVER] HTTP server closed');
      process.exit(0);
    });
  };
  
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
  
  return server;
}

// Process error handlers
process.on('uncaughtException', handleErrorCode);
process.on('unhandledRejection', handleRuntimeError);

// Start the server
startServer().catch((err) => {
  console.error('[SERVER] Failed to start:', err);
  process.exit(1);
});

export { startServer };
