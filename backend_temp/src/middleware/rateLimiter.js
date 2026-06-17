import NodeCache from 'node-cache';

const cache = new NodeCache({ stdTTL: 60 }); // 60 seconds default TTL

/**
 * Rate limiter middleware
 * @param {number} maxRequests - Maximum requests allowed in the time window
 * @param {number} windowSeconds - Time window in seconds
 */
export const rateLimiter = (maxRequests = 100, windowSeconds = 60) => {
    return (req, res, next) => {
        const ip = req.ip || req.connection.remoteAddress;
        const key = `rate_${ip}_${req.path}`;
        
        const current = cache.get(key) || { count: 0, firstRequest: Date.now() };
        
        // Reset if window has passed
        if (Date.now() - current.firstRequest > windowSeconds * 1000) {
            current.count = 0;
            current.firstRequest = Date.now();
        }
        
        current.count++;
        cache.set(key, current, windowSeconds);
        
        // Set rate limit headers
        res.setHeader('X-RateLimit-Limit', maxRequests);
        res.setHeader('X-RateLimit-Remaining', Math.max(0, maxRequests - current.count));
        res.setHeader('X-RateLimit-Reset', Math.ceil((current.firstRequest + windowSeconds * 1000) / 1000));
        
        if (current.count > maxRequests) {
            return res.status(429).json({
                message: 'Too many requests, please try again later',
                retryAfter: windowSeconds
            });
        }
        
        next();
    };
};

// Specific limiters for different routes
export const authLimiter = rateLimiter(10, 60); // 10 requests per minute for auth
export const apiLimiter = rateLimiter(100, 60); // 100 requests per minute for API
export const uploadLimiter = rateLimiter(20, 60); // 20 uploads per minute
