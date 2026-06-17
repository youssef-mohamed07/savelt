import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// Get the directory name in an ES Module environment
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Define log file path (relative to the current directory)
const logFilePath = path.join(__dirname, "../../log.txt");

// Function to log messages to a file with a timestamp
export function logToFile(message, isError = false) {
    const timestamp = new Date().toLocaleString("en-US", { timeZone: "Africa/Cairo" });
    const logMessage = `[${timestamp}] ${isError ? "[ERROR] " : ""}${message}\n`;
    fs.appendFileSync(logFilePath, logMessage, "utf8");
}

// Save original functions
const originalConsoleLog = console.log;
const originalConsoleError = console.error;

// Override console.log to log normal messages
console.log = (...args) => {
    originalConsoleLog(...args);
    logToFile(args.map(arg => (typeof arg === "object" ? JSON.stringify(arg) : arg)).join(" "));
};

// Override console.error to log error messages
console.error = (...args) => {
    originalConsoleError(...args);
    logToFile(args.map(arg => (typeof arg === "object" ? JSON.stringify(arg) : arg)).join(" "), true);
};
