import jwt from 'jsonwebtoken'; // JWT for token creation
import bcrypt from 'bcryptjs'; // Bcrypt for password hashing/comparison
import configDotenv from 'dotenv';
import passport from 'passport';
import { AppError } from '../../utils/AppError.js'; // Custom error handling class
import { catchError } from '../../utils/catchError.js'; // Error handling middleware
import { User } from '../../DB/models/user.model.js';

configDotenv.config();

import { sendOTPEmail, sendPasswordResetOTPEmail, sendWelcomeEmail } from '../../utils/emailService.js';
import { verifyGoogleIdToken, isGoogleAuthConfigured } from '../../services/googleAuth.service.js';
import { v4 as uuidv4 } from 'uuid';

// Function: Creates a new user account and sends OTP verification email
const signupAndSendOtp = catchError(async (req, res, next) => {
    console.log('[signupAndSendOtp] START', { body: req.body });
    try {
        if (!req.body.email) {
            console.error('[signupAndSendOtp] ERROR: Email not provided', { body: req.body });
            return next(new AppError('Email is required', 400));
        }
        if (!req.body.password) {
            console.error('[signupAndSendOtp] ERROR: Password not provided', { body: req.body });
            return next(new AppError('Password is required', 400));
        }
        if (!req.body.phone) {
            console.error('[signupAndSendOtp] ERROR: Name not provided', { body: req.body });
            return next(new AppError('Name is required', 400));
        }
        let email = req.body.email;
        email = email.toLowerCase();
        const userExists = await User.findOne({ email: email });
        if (userExists) {
            console.error('[signupAndSendOtp] ERROR: Email already taken', { email: email });
            return res.status(409).json({ message: 'This email is already taken', flag: true });
        }
        const otp = (Math.floor(100000 + Math.random() * 900000)).toString();
        req.body.password = await bcrypt.hash(req.body.password, 10);
        if (!req.body.name) {
            req.body.name = req.body.firstName + ' ' + req.body.lastName;
        }
        const user = await User.create({
            fullname: req.body.name,
            firstName: req.body.firstName,
            lastName: req.body.lastName,
            email: email,
            password: req.body.password,
            phone: req.body.phone,
            country: req.body.country,
            countryCode: req.body.countryCode,
            OTP: otp,
        });
        console.log('[signupAndSendOtp] SUCCESS', { user: user.email, name: user.name });

        // Attempt to send OTP email; do not fail signup if email sending fails
        try {
            const mailResult = await sendOTPEmail(user.email, otp, user.name || user.fullname || user.firstName);
            if (!mailResult.success) {
                console.error('[signupAndSendOtp] EMAIL ERROR', mailResult.error);
            } else {
                console.log('[signupAndSendOtp] EMAIL SENT', mailResult.messageId);
            }
        } catch (emailErr) {
            console.error('[signupAndSendOtp] EMAIL THROW ERROR', emailErr);
        }

        res.json({ message: 'Signup successful, OTP sent to email' });
    } catch (err) {
        console.error('[signupAndSendOtp] ERROR', { error: err, body: req.body });
        next(err);
    }
});

// Function: ReSends OTP to user email
const resendOtp = catchError(async (req, res, next) => {
    console.log('[resendOtp] START', { body: req.body });
    try {
        const userExists = await User.findOne({ email: req.body.email });
        const otp = userExists?.OTP;
        if (!otp) {
            console.error('[resendOtp] ERROR: OTP not found or user registered before', { email: req.body.email });
            return next(new AppError('OTP not found', 404));
        }
        console.log('[resendOtp] SUCCESS', { email: userExists.email, otp });

        try {
            const mailResult = await sendOTPEmail(userExists.email, otp, userExists.name || userExists.fullname || userExists.firstName);
            if (!mailResult.success) {
                console.error('[resendOtp] EMAIL ERROR', mailResult.error);
            } else {
                console.log('[resendOtp] EMAIL SENT', mailResult.messageId);
            }
        } catch (emailErr) {
            console.error('[resendOtp] EMAIL THROW ERROR', emailErr);
        }

        res.json({ message: 'resend OTP successful, OTP sent to email' });
    } catch (err) {
        console.error('[resendOtp] ERROR', { error: err, body: req.body });
        next(err);
    }
});

// Function: Verifies OTP and completes user account setup
const configurationOTP = catchError(async (req, res, next) => {
    console.log('[configurationOTP] START', { body: req.body });
    try {
        
        let user = await User.findOneAndUpdate(
            { OTP: req.body.otp },
            { confEmail: true, OTP: null },
            { new: true }
        );
        if (!user) {
            console.error('[configurationOTP] ERROR: Invalid OTP provided', { otp: req.body.otp });
            return next(new AppError('some issue in OTP authorization'));
        }
        const token = jwt.sign({ id: user._id, role: user.role, email: user.email }, process.env.JWT_KEY);
        console.log('[configurationOTP] SUCCESS', { user: user.email, token });

        try {
            const mailResult = await sendWelcomeEmail(user.email, user.name || user.fullname || user.firstName);
            if (!mailResult.success) {
                console.error('[configurationOTP] WELCOME EMAIL ERROR', mailResult.error);
            } else {
                console.log('[configurationOTP] WELCOME EMAIL SENT', mailResult.messageId);
            }
        } catch (emailErr) {
            console.error('[configurationOTP] WELCOME EMAIL THROW', emailErr);
        }

        res.status(201).json({ message: 'User added successfully', user, token });
    } catch (err) {
        console.error('[configurationOTP] ERROR', { error: err, body: req.body });
        next(err);
    }
});

// Function: Authenticates user login with email and password
const signin = catchError(async (req, res, next) => {
    console.log('[signin] START', { body: req.body });
    try {
        const user = await User.findOne({ email: req.body.email });
        if (!user) {
            console.error('[signin] ERROR: Invalid email or password', { email: req.body.email });
            return next(new AppError('Invalid email or password', 401));
        }
        if (user.confEmail === false) {
            console.warn('[signin] WARNING: User not confirmed, OTP resent', { email: user.email });
            return res.status(404).json({ message: 'User not confirmed with OTP, we resend the OTP', returnToSignup: true });
        }
        if (bcrypt.compareSync(req.body.password, user.password)) {
            const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_KEY);
            console.log('[signin] SUCCESS', { user: user.name, token });
            return res.status(200).json({ message: 'Login successfully', user, token });
        }
        console.error('[signin] ERROR: Invalid password provided', { email: req.body.email });
        return next(new AppError('Invalid email or password', 401));
    } catch (err) {
        console.error('[signin] ERROR', { error: err, body: req.body });
        next(err);
    }
});

// Function: Updates user password after verification of old password
const changePassword = catchError(async (req, res, next) => {
    console.log('[changePassword] START', { user: req.user, body: req.body });
    try {
        if (!req.body.oldPassword || !req.body.newPassword) {
            console.error('[changePassword] ERROR: Missing required fields', { body: req.body });
            return next(new AppError('Missing required fields', 400));
        }
        if (req.body.oldPassword === req.body.newPassword) {
            console.error('[changePassword] ERROR: New password same as old', { user: req.user });
            return next(new AppError('New password cannot be the same as the old password', 400));
        }
        const user = await User.findById(req.user._id);
        if (!user) {
            console.error('[changePassword] ERROR: User not found', { user: req.user });
            return next(new AppError('Invalid email or password', 401));
        }
        if (!bcrypt.compareSync(req.body.oldPassword, user.password)) {
            console.error('[changePassword] ERROR: Old password incorrect', { user: req.user });
            return next(new AppError('Old password is incorrect', 400));
        }
        user.password = bcrypt.hashSync(req.body.newPassword, 10);
        await user.save();
        const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_KEY);
        console.log('[changePassword] SUCCESS', { user: user.email, token });
        return res.status(200).json({ message: 'Password changed successfully', user, token });
    } catch (err) {
        console.error('[changePassword] ERROR', { error: err, user: req.user, body: req.body });
        next(err);
    }
});

// Function: Initiates password recovery by sending a 6-digit OTP
const forgetPassword = catchError(async (req, res, next) => {
    console.log('[forgetPassword] START', { body: req.body });
    try {
        const email = (req.body.email || '').toLowerCase().trim();
        const user = await User.findOne({ email });
        if (!user) {
            console.error('[forgetPassword] ERROR: Email not found', { email });
            return next(new AppError('User with this email does not exist', 404));
        }
        if (!user.confEmail) {
            return next(new AppError('Please verify your email before resetting password', 400));
        }

        const displayName = user.fullname || user.name || user.firstName || 'User';
        const otp = (Math.floor(100000 + Math.random() * 900000)).toString();
        user.resetOTP = otp;
        user.resetOTPExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
        await user.save();

        console.log('[forgetPassword] SUCCESS', { email: user.email });

        try {
            const mailResult = await sendPasswordResetOTPEmail(user.email, otp, displayName);
            if (!mailResult.success) {
                console.error('[forgetPassword] EMAIL ERROR', mailResult.error);
            } else {
                console.log('[forgetPassword] OTP EMAIL SENT', mailResult.messageId);
            }
        } catch (emailErr) {
            console.error('[forgetPassword] EMAIL THROW ERROR', emailErr);
        }

        res.status(200).json({ message: 'Password reset code sent to your email' });
    } catch (err) {
        console.error('[forgetPassword] ERROR', { error: err, body: req.body });
        next(err);
    }
});

// Function: Completes password reset using email + OTP
const setNewPassword = catchError(async (req, res, next) => {
    console.log('[setNewPassword] START', { body: req.body });
    try {
        const email = (req.body.email || '').toLowerCase().trim();
        const otp = (req.body.otp || '').trim();
        const { newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return next(new AppError('Email, OTP and new password are required', 400));
        }

        const user = await User.findOne({ email });
        if (!user || !user.resetOTP || user.resetOTP !== otp) {
            console.error('[setNewPassword] ERROR: Invalid OTP', { email });
            return next(new AppError('Invalid or expired reset code', 400));
        }

        if (!user.resetOTPExpiresAt || user.resetOTPExpiresAt < new Date()) {
            user.resetOTP = null;
            user.resetOTPExpiresAt = null;
            await user.save();
            return next(new AppError('Reset code has expired. Request a new one.', 400));
        }

        if (bcrypt.compareSync(newPassword, user.password)) {
            return next(new AppError('New password cannot be the same as the old password', 400));
        }

        user.password = bcrypt.hashSync(newPassword, 10);
        user.resetOTP = null;
        user.resetOTPExpiresAt = null;
        user.passwordChangedAt = new Date();
        await user.save();

        console.log('[setNewPassword] SUCCESS', { user: user.email });
        res.status(200).json({ message: 'Password reset successfully' });
    } catch (error) {
        console.error('[setNewPassword] ERROR', { error, body: req.body });
        return next(new AppError('Failed to reset password', 400));
    }
});

// Google Sign-In (mobile) — verify ID token from Flutter google_sign_in
const googleSignIn = catchError(async (req, res, next) => {
    console.log('[googleSignIn] START');
    try {
        if (!isGoogleAuthConfigured()) {
            return next(new AppError('Google Sign-In is not configured on the server', 503));
        }

        const { idToken } = req.body;
        if (!idToken) {
            return next(new AppError('Google ID token is required', 400));
        }

        let payload;
        try {
            payload = await verifyGoogleIdToken(idToken);
        } catch (err) {
            console.error('[googleSignIn] Token verify failed', err.message);
            return next(new AppError('Invalid Google token', 401));
        }

        const email = payload.email.toLowerCase().trim();
        const googleId = payload.sub;
        const fullName = payload.name || payload.given_name || 'User';
        const nameParts = fullName.trim().split(/\s+/);
        const firstName = nameParts[0] || 'User';
        const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : firstName;

        let user = await User.findOne({ $or: [{ googleId }, { email }] });

        if (user) {
            if (user.isDeleted) {
                return next(new AppError('Account not found', 404));
            }
            if (!user.googleId) user.googleId = googleId;
            if (!user.confEmail) user.confEmail = true;
            if (user.authProvider !== 'google') user.authProvider = 'google';
            if (!user.fullname) user.fullname = fullName;
            await user.save();
        } else {
            user = await User.create({
                fullname: fullName,
                firstName,
                lastName,
                email,
                googleId,
                authProvider: 'google',
                confEmail: true,
                password: await bcrypt.hash(uuidv4(), 10),
                phone: '',
                country: 'Egypt',
                countryCode: '+20',
            });

            try {
                await sendWelcomeEmail(user.email, fullName);
            } catch (emailErr) {
                console.error('[googleSignIn] Welcome email error', emailErr);
            }
        }

        const token = jwt.sign(
            { id: user._id, role: user.role, email: user.email },
            process.env.JWT_KEY,
        );

        console.log('[googleSignIn] SUCCESS', { email: user.email });
        return res.status(200).json({
            message: 'Google sign-in successful',
            user,
            token,
        });
    } catch (err) {
        console.error('[googleSignIn] ERROR', err);
        next(err);
    }
});

// Google authentication setup (legacy web redirect — optional)
const googleAuth = [
  (req, res, next) => {
    console.log('[googleAuth] START - redirecting user to Google for authentication');
    next();
},
  passport.authenticate('google', { scope: ['profile', 'email'] }),
];

// Google callback handler after authentication
const googleCallback = [
  (req, res, next) => {
    console.log('[googleCallback] START - received callback from Google', { query: req.query });
    next();
  },
  passport.authenticate('google', { session: false, failureRedirect: '/auth/failure' }),
  (req, res) => {
    console.log('[googleCallback] AUTHORIZED - user successfully authenticated', { userId: req.user.id, email: req.user.email });

    const token = jwt.sign(
      { id: req.user.id, email: req.user.email },
      process.env.JWT_KEY,
      { expiresIn: '7d' }
    );

     console.log('[googleCallback] SUCCESS - JWT issued', { token });
     
     const frontendUrl = 'https://www..com'; 
     
     return res.redirect(`${frontendUrl}?token=${token}`);
  },
];


// Function: Get user profile
const getProfile = catchError(async (req, res, next) => {
    console.log('[getProfile] START', { userId: req.user._id });
    const user = await User.findById(req.user._id).select('-password -OTP');
    if (!user) {
        return next(new AppError('User not found', 404));
    }
    res.status(200).json({ message: 'Profile retrieved successfully', user });
});

// Function: Update user profile
const updateProfile = catchError(async (req, res, next) => {
    console.log('[updateProfile] START', { userId: req.user._id, body: req.body });
    const allowedFields = ['firstName', 'lastName', 'fullname', 'phone'];
    const updates = {};
    
    allowedFields.forEach(field => {
        if (req.body[field] !== undefined) {
            updates[field] = req.body[field];
        }
    });

    if (updates.firstName || updates.lastName) {
        const firstName = updates.firstName || req.user.firstName;
        const lastName = updates.lastName || req.user.lastName;
        updates.fullname = `${firstName} ${lastName}`;
    }

    const user = await User.findByIdAndUpdate(req.user._id, updates, { new: true }).select('-password -OTP');
    
    if (!user) {
        return next(new AppError('User not found', 404));
    }
    
    console.log('[updateProfile] SUCCESS', { userId: user._id });
    res.status(200).json({ message: 'Profile updated successfully', user });
});

// Function: Delete user account
const deleteAccount = catchError(async (req, res, next) => {
    console.log('[deleteAccount] START', { userId: req.user._id });
    
    const { password } = req.body;
    if (!password) {
        return next(new AppError('Password is required to delete account', 400));
    }

    const user = await User.findById(req.user._id);
    if (!bcrypt.compareSync(password, user.password)) {
        return next(new AppError('Invalid password', 401));
    }

    // Import models to delete related data
    const { Transactions } = await import('../../DB/models/transactions.model.js');
    const { Category } = await import('../../DB/models/category.model.js');
    const { Item } = await import('../../DB/models/item.model.js');

    // Delete all user data
    await Promise.all([
        Transactions.deleteMany({ user: req.user._id }),
        Category.deleteMany({ user: req.user._id }),
        Item.deleteMany({ user: req.user._id }),
        User.findByIdAndDelete(req.user._id)
    ]);

    console.log('[deleteAccount] SUCCESS', { userId: req.user._id });
    res.status(200).json({ message: 'Account deleted successfully' });
});

export {
    signupAndSendOtp,
    changePassword,
    signin,
    configurationOTP,
    forgetPassword,
    setNewPassword,
    resendOtp,
    googleAuth,
    googleCallback,
    getProfile,
    updateProfile,
    deleteAccount,
    googleSignIn,
};