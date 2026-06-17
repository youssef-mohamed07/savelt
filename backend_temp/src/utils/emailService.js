import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

// Create transporter
const createTransporter = () => {
    return nodemailer.createTransport({
        service: process.env.EMAIL_SERVICE || 'gmail',
        auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS
        }
    });
};

/**
 * Send email
 * @param {Object} options - Email options
 * @param {string} options.to - Recipient email
 * @param {string} options.subject - Email subject
 * @param {string} options.text - Plain text content
 * @param {string} options.html - HTML content
 */
export const sendEmail = async ({ to, subject, text, html }) => {
    try {
        const transporter = createTransporter();
        
        const mailOptions = {
            from: `"Expense Tracker" <${process.env.EMAIL_USER}>`,
            to,
            subject,
            text,
            html
        };
        
        const info = await transporter.sendMail(mailOptions);
        console.log('[EMAIL] Message sent:', info.messageId);
        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('[EMAIL] Error sending email:', error.message);
        return { success: false, error: error.message };
    }
};

/**
 * Send OTP email
 * @param {string} email - Recipient email
 * @param {string} otp - OTP code
 * @param {string} name - User name
 */
export const sendOTPEmail = async (email, otp, name = 'User') => {
    const subject = 'Your Verification Code - Expense Tracker';
    
    const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #4F46E5; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .otp-box { background: #4F46E5; color: white; font-size: 32px; letter-spacing: 8px; padding: 20px; text-align: center; border-radius: 10px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Expense Tracker</h1>
                </div>
                <div class="content">
                    <h2>Hello ${name}!</h2>
                    <p>Your verification code is:</p>
                    <div class="otp-box">${otp}</div>
                    <p>This code will expire in 10 minutes.</p>
                    <p>If you didn't request this code, please ignore this email.</p>
                </div>
                <div class="footer">
                    <p>© ${new Date().getFullYear()} Expense Tracker. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
    `;
    
    const text = `Hello ${name}!\n\nYour verification code is: ${otp}\n\nThis code will expire in 10 minutes.\n\nIf you didn't request this code, please ignore this email.`;
    
    return sendEmail({ to: email, subject, text, html });
};

/**
 * Send password reset email
 * @param {string} email - Recipient email
 * @param {string} resetLink - Password reset link
 * @param {string} name - User name
 */
export const sendPasswordResetEmail = async (email, resetLink, name = 'User') => {
    const subject = 'Password Reset Request - Expense Tracker';
    
    const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #4F46E5; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .button { display: inline-block; background: #4F46E5; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Expense Tracker</h1>
                </div>
                <div class="content">
                    <h2>Hello ${name}!</h2>
                    <p>We received a request to reset your password.</p>
                    <p>Click the button below to reset your password:</p>
                    <a href="${resetLink}" class="button">Reset Password</a>
                    <p>This link will expire in 1 hour.</p>
                    <p>If you didn't request this, please ignore this email.</p>
                </div>
                <div class="footer">
                    <p>© ${new Date().getFullYear()} Expense Tracker. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
    `;
    
    const text = `Hello ${name}!\n\nWe received a request to reset your password.\n\nClick the link below to reset your password:\n${resetLink}\n\nThis link will expire in 1 hour.\n\nIf you didn't request this, please ignore this email.`;
    
    return sendEmail({ to: email, subject, text, html });
};

/**
 * Send welcome email
 * @param {string} email - Recipient email
 * @param {string} name - User name
 */
export const sendWelcomeEmail = async (email, name = 'User') => {
    const subject = 'Welcome to Expense Tracker!';
    
    const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #4F46E5; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .feature { padding: 10px 0; border-bottom: 1px solid #ddd; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Welcome to Expense Tracker!</h1>
                </div>
                <div class="content">
                    <h2>Hello ${name}!</h2>
                    <p>Thank you for joining Expense Tracker. We're excited to help you manage your finances!</p>
                    <h3>What you can do:</h3>
                    <div class="feature">📝 Track expenses with text, voice, or images</div>
                    <div class="feature">📊 View detailed analytics and reports</div>
                    <div class="feature">📁 Organize expenses by categories</div>
                    <div class="feature">📤 Export your data anytime</div>
                    <p>Start tracking your expenses today!</p>
                </div>
                <div class="footer">
                    <p>© ${new Date().getFullYear()} Expense Tracker. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
    `;
    
    const text = `Hello ${name}!\n\nThank you for joining Expense Tracker. We're excited to help you manage your finances!\n\nWhat you can do:\n- Track expenses with text, voice, or images\n- View detailed analytics and reports\n- Organize expenses by categories\n- Export your data anytime\n\nStart tracking your expenses today!`;
    
    return sendEmail({ to: email, subject, text, html });
};
