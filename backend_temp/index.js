
// Third-party imports
import express from "express";
import cors from "cors";
import configDotenv from "dotenv";

// Load environment variables first
configDotenv.config();

// Local imports - Utils
import "./src/utils/logger.js"; // Enable logging
import { handleRuntimeError, handleErrorCode } from "./src/utils/outError.js";
import { GlobalError } from "./src/utils/GlobalError.js";
import { URL_Error } from "./src/utils/URL_Catch.js";

// Local imports - Middleware
import { sanitizeInput, preventNoSQLInjection } from "./src/middleware/sanitize.js";
import { apiLimiter } from "./src/middleware/rateLimiter.js";

// Local imports - Database & Routes
import { dbConnection } from "./src/DB/dbConnection.js";
import { bootstrap } from "./src/module/bootStrap.js";

// Initialize Express app
const app = express();
const port = process.env.PORT || 3000;

// Security Middleware
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
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

// Serve static files
app.use("/uploads", express.static("src/uploads")); // Serve uploads folder
app.use("/arrayFiles", express.static("arrayFiles")); // Serve arrayFiles folder
app.use("/ShuffleFiles", express.static("ShuffleFiles")); // Serve ShuffleFiles folder

// Bootstrap routes
bootstrap(app); // Load the routes dynamically

// Error Handling Middleware
app.use(GlobalError); // Handle global errors

// Process-level error handling
process.on("uncaughtException", handleErrorCode); // Handle uncaught exceptions
process.on("unhandledRejection", handleRuntimeError); // Handle unhandled promise rejections

// Root route
app.get("/api", (req, res) => res.send(" Server is running!")); // Basic health check route

// Catch all undefined routes
app.use(URL_Error);

// Log server start and database connection
console.log("[SERVER] Server is starting...");

// Start the server using an http server so WebSocket can attach or run separately
import http from 'http';
import { startWsServer } from "./src/module/analysis/wsServer.js";

// Default HTTP port (3001) to match your expectation
const httpPort = process.env.PORT || 3001;

const server = http.createServer(app);
server.listen(httpPort, "0.0.0.0", () => console.log(`[SERVER] Server listening on port ${httpPort}!`));

// Start standalone WebSocket server for real-time analysis pushes (port 3002)
startWsServer({ port: process.env.WS_PORT ? Number(process.env.WS_PORT) : 3002 });
