import { OAuth2Client } from 'google-auth-library';

let _client = null;

function getClient() {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    if (!clientId) {
        throw new Error('GOOGLE_CLIENT_ID is not configured');
    }
    if (!_client) {
        _client = new OAuth2Client(clientId);
    }
    return _client;
}

export async function verifyGoogleIdToken(idToken) {
    const client = getClient();
    const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    if (!payload?.email) {
        throw new Error('Google account has no email');
    }
    if (payload.email_verified === false) {
        throw new Error('Google email is not verified');
    }
    return payload;
}

export function isGoogleAuthConfigured() {
    return Boolean(process.env.GOOGLE_CLIENT_ID?.trim());
}
