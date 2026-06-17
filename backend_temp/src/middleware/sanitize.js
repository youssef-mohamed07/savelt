/**
 * Sanitize input to prevent XSS and injection attacks
 */

// Remove potentially dangerous characters
const sanitizeString = (str) => {
    if (typeof str !== 'string') return str;
    
    return str
        .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '') // Remove script tags
        .replace(/<[^>]*>/g, '') // Remove HTML tags
        .replace(/javascript:/gi, '') // Remove javascript: protocol
        .replace(/on\w+=/gi, '') // Remove event handlers
        .trim();
};

// Recursively sanitize object
const sanitizeObject = (obj) => {
    if (obj === null || obj === undefined) return obj;
    
    if (typeof obj === 'string') {
        return sanitizeString(obj);
    }
    
    if (Array.isArray(obj)) {
        return obj.map(item => sanitizeObject(item));
    }
    
    if (typeof obj === 'object') {
        const sanitized = {};
        for (const key of Object.keys(obj)) {
            // Skip MongoDB operators
            if (key.startsWith('$')) continue;
            sanitized[key] = sanitizeObject(obj[key]);
        }
        return sanitized;
    }
    
    return obj;
};

/**
 * Merge a plain sanitized object into a target Express may expose as read-only
 * on `req` (getter-only `req.query` / `req.params`). Mutate `target` in place.
 * @param {Record<string, unknown>} target
 * @param {Record<string, unknown>} source
 */
function mergeIntoRequestDict(target, source) {
    if (!target || typeof target !== 'object' || !source || typeof source !== 'object') {
        return;
    }
    const prevKeys = Object.keys(target);
    for (const key of prevKeys) {
        if (!Object.prototype.hasOwnProperty.call(source, key)) {
            delete target[key];
        }
    }
    for (const [key, value] of Object.entries(source)) {
        target[key] = value;
    }
}

/**
 * Middleware to sanitize request body, query, and params
 */
export const sanitizeInput = (req, res, next) => {
    try {
        if (req.body && typeof req.body === 'object') {
            req.body = sanitizeObject(req.body);
        }
        
        if (req.query && typeof req.query === 'object') {
            mergeIntoRequestDict(req.query, sanitizeObject(req.query));
        }
        
        if (req.params && typeof req.params === 'object') {
            mergeIntoRequestDict(req.params, sanitizeObject(req.params));
        }
        
        next();
    } catch (error) {
        console.error('[SANITIZE] Error:', error.message);
        next();
    }
};

/**
 * Prevent NoSQL injection by removing $ operators from user input
 */
export const preventNoSQLInjection = (req, res, next) => {
    try {
        const removeOperators = (obj) => {
            if (typeof obj !== 'object' || obj === null) return obj;
            
            const cleaned = {};
            for (const key of Object.keys(obj)) {
                if (!key.startsWith('$')) {
                    cleaned[key] = typeof obj[key] === 'object' 
                        ? removeOperators(obj[key]) 
                        : obj[key];
                }
            }
            return cleaned;
        };
        
        if (req.body && typeof req.body === 'object') {
            req.body = removeOperators(req.body);
        }
        
        if (req.query && typeof req.query === 'object') {
            mergeIntoRequestDict(req.query, removeOperators(req.query));
        }
        
        next();
    } catch (error) {
        console.error('[NOSQL_INJECTION] Error:', error.message);
        next();
    }
};
