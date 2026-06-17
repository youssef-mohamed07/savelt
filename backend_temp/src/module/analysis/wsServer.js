import { WebSocketServer } from 'ws';

let wss = null;
// Map: userId (string) → Set of WebSocket connections
const userClients = new Map();

export function startWsServer(options = {}) {
  if (wss) return wss;
  const port = options.port || 3002;
  wss = new WebSocketServer({ port });

  wss.on('connection', (ws, req) => {
    // Client sends userId as query param: ws://host:3002?userId=xxx
    const url = new URL(req.url, 'ws://localhost');
    const userId = url.searchParams.get('userId');

    if (userId) {
      if (!userClients.has(userId)) userClients.set(userId, new Set());
      userClients.get(userId).add(ws);
      console.log(`[WS] User ${userId} connected. Total connections: ${_totalClients()}`);
    } else {
      // Legacy: no userId — add to a general pool
      if (!userClients.has('__all__')) userClients.set('__all__', new Set());
      userClients.get('__all__').add(ws);
      console.log(`[WS] Anonymous client connected`);
    }

    ws.on('close', () => {
      // Remove from all user sets
      for (const [uid, clients] of userClients.entries()) {
        clients.delete(ws);
        if (clients.size === 0) userClients.delete(uid);
      }
      console.log(`[WS] Client disconnected. Total: ${_totalClients()}`);
    });

    ws.on('error', (err) => {
      console.error('[WS] Client error', err.message);
    });
  });

  console.log(`[WS] WebSocket server started on ws://0.0.0.0:${port}`);
  return wss;
}

function _totalClients() {
  let total = 0;
  for (const clients of userClients.values()) total += clients.size;
  return total;
}

function _sendToUser(userId, message) {
  const raw = JSON.stringify(message);
  const clients = userClients.get(userId?.toString());
  if (!clients) return;
  for (const ws of clients) {
    if (ws.readyState === ws.OPEN) ws.send(raw);
  }
}

export function broadcast(message) {
  const raw = JSON.stringify(message);
  for (const clients of userClients.values()) {
    for (const ws of clients) {
      if (ws.readyState === ws.OPEN) ws.send(raw);
    }
  }
}

/**
 * Send analytics update to a specific user only.
 * @param {string|ObjectId} userId
 * @param {object} payload
 */
export function broadcastAnalysis(payload, userId) {
  const message = { type: 'analytics_update', data: payload };
  if (userId) {
    _sendToUser(userId.toString(), message);
  } else {
    broadcast(message);
  }
}
