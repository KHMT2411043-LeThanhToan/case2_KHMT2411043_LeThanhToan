
const transporter = require('../config/email');

const sendEmail = async ({ to, subject, text, html }) => {
    try {
        const info = await transporter.sendMail({
            from: process.env.SMTP_USER,
            to,
            subject,
            text,
            html,
        });

        console.log('Email sent:', info.messageId);

        return {
            success: true,
            messageId: info.messageId,
        };
    } catch (error) {
        console.error('Email sending failed:', error.message);

        return {
            success: false,
            error: error.message,
        };
    }
};

module.exports = { sendEmail };
