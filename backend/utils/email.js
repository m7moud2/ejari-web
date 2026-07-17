const nodemailer = require('nodemailer');

const sendEmail = async (options) => {
    // إنشاء ناقل SMTP
    const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: process.env.SMTP_PORT || 587,
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        },
        tls: {
            rejectUnauthorized: false
        }
    });

    const message = {
        from: `${process.env.FROM_NAME || 'Ejari Elite'} <${process.env.FROM_EMAIL || 'noreply@ejari.app'}>`,
        to: options.email,
        subject: options.subject,
        text: options.message,
        html: options.html
    };

    const info = await transporter.sendMail(message);
    console.log('Message sent: %s', info.messageId);

    return info;
};

module.exports = sendEmail;
