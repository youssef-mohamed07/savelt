import dotenv from "dotenv";
dotenv.config();
import WebSocket from 'ws';

// وصلّي على WebSocket server
const ws = new WebSocket('ws://localhost:3002');

ws.on('open', () => {
  console.log('✅ Connected to WebSocket server');
});

ws.on('message', (message) => {
  console.log('📩 Received:', message.toString());
});
