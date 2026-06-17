import { Router } from 'express';
import { 
    signupAndSendOtp, 
    configurationOTP, 
    signin, 
    changePassword, 
    forgetPassword, 
    setNewPassword, 
    resendOtp, 
    googleCallback, 
    googleAuth,
    getProfile,
    updateProfile,
    deleteAccount
} from './auth.controller.js';
import { validate } from '../../middleware/validate.js';
import { otpValidationSchema, signinValidationSchema, signupValidationSchema } from './auth.validation.js';
import { allowedTo, protectedRoutes } from '../../middleware/auth.js';

export const authRouter = Router();
export const googleRouter = Router();

// User Signup (register and send OTP)
authRouter.post('/signup', signupAndSendOtp);

// Confirm OTP
authRouter.post('/signup/configurationOTP', configurationOTP);

// User Signin
authRouter.post('/signin', signin);

// Change Password (protected)
authRouter.post('/changePassword', protectedRoutes, changePassword);

// Resend OTP
authRouter.post('/resendOTP', resendOtp);

// Forget Password
authRouter.post('/forgetPassword', forgetPassword);

// Set New Password (with token)
authRouter.post('/setNewPassword', setNewPassword);

// Profile routes
authRouter.get('/profile', protectedRoutes, getProfile);
authRouter.put('/profile', protectedRoutes, updateProfile);
authRouter.delete('/account', protectedRoutes, deleteAccount);

