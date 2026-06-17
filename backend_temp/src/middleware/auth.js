import jwt from 'jsonwebtoken';
import configDotenv from 'dotenv';
import { AppError } from '../utils/AppError.js';
import { catchError } from '../utils/catchError.js';
import { User } from '../DB/models/user.model.js';

configDotenv.config();

// Middleware to protect routes by verifying JWT token and user status
const protectedRoutes = catchError(async (req, res, next) => {
    const clientIP = req.ip || req.connection.remoteAddress;
    const { token } = req.headers;
    let flag_login = true;
    if(req.method === 'GET' && req.originalUrl === '/api/myData') flag_login = false;
    
    if(flag_login) console.log(`[AUTH] Start: ${req.method} ${req.originalUrl} | IP: ${clientIP}`);

    if (!token) {
        if(flag_login) console.log(`[AUTH][DENIED] No token`);
        return next(new AppError('Missing token..!', 401));
    }
    try {
        const userPayload = jwt.verify(token, process.env.JWT_KEY);
        const user = await User.findById(userPayload.id);
        if (!user) {
            if(flag_login) console.log(`[AUTH][DENIED] Invalid user ID`);
            return next(new AppError('User not found..!', 401));
        }
        if (!user.fullname || user.fullname === "Undefined undefined") {
            if (user.firstName && user.lastName) {
                const newName = `${user.firstName} ${user.lastName}`;
                await User.findByIdAndUpdate(userPayload.id, { fullname: newName });
                user.fullname = newName;
            } else if (user.fullname) {
                // fullname exists, continue
            } else {
                if(flag_login) console.log(`[AUTH][DENIED] Missing user name`);
                return next(new AppError('User name not found..!', 401));
            }
        }
        if (user.isBlocked) {
            if(flag_login) console.log(`[AUTH][DENIED] Blocked user: ${user.name}`);
            return next(new AppError('User is blocked..!', 401));
        }
        if (user.isDeleted) {
            if(flag_login) console.log(`[AUTH][DENIED] Deleted user account`);
            return next(new AppError('Account no longer available..!', 401));
        }
        if (!user.confEmail) {
            if(flag_login) console.log(`[AUTH][DENIED] Email not confirmed: ${user.name}`);
            return next(new AppError('Email not confirmed..!', 401));
        }
        const tokenIssuedAt = userPayload.iat;
        const passwordChangedAt = user.passwordChangedAt?.getTime() / 1000;
        if (passwordChangedAt && tokenIssuedAt < passwordChangedAt) {
            if(flag_login) console.log(`[AUTH][DENIED] Token outdated (password changed)`);
            return next(new AppError('Token time issue..!', 401));
        }
        req.user = user;
        req.requestId = Math.random().toString(36).substring(2, 10);
        if(flag_login) console.log(`[AUTH][GRANTED] User: ${user.fullname || user.firstName} | Role: ${user.role}`);
        return next();
    } catch (err) {
        if(flag_login) console.log(`[AUTH][ERROR] Invalid token (${err.name})`);
        return next(new AppError('Invalid token', 401));
    }
});

// Middleware to authorize access based on user roles
const allowedTo = (...roles) => {
    // Returns a middleware that checks if the user has one of the allowed roles
    return catchError(async (req, res, next) => {
        const user = req.user;
        if (!user?.role) {
             console.log(`[AUTHZ][DENIED] No role for user: ${user.name}`);
            return next(new AppError('User role not found..!', 401));
        }
        if (!roles.includes(user.role)) {
             console.log(`[AUTHZ][DENIED] ${user.name} | Role "${user.role}" not in [${roles.join(', ')}]`);
            return next(new AppError('Role not authorized..!', 401));
        }
         console.log(`[AUTHZ][GRANTED] ${user.name} | Role: ${user.role}`);
        return next();
    });
};

export { 
    protectedRoutes,
    allowedTo 
};
