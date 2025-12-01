const dotenv = require('dotenv');

// تحميل متغيرات البيئة
dotenv.config();

module.exports = {
    // إعدادات الخادم
    PORT: process.env.PORT || 5000,
    NODE_ENV: process.env.NODE_ENV || 'development',
    
    // إعدادات قاعدة البيانات
    MONGO_URI: process.env.MONGO_URI,
    
    // JWT
    JWT_SECRET: process.env.JWT_SECRET,
    JWT_EXPIRE: process.env.JWT_EXPIRE || '30d',
    JWT_COOKIE_EXPIRE: process.env.JWT_COOKIE_EXPIRE || 30,
    
    // SMTP
    SMTP_HOST: process.env.SMTP_HOST,
    SMTP_PORT: process.env.SMTP_PORT,
    SMTP_EMAIL: process.env.SMTP_EMAIL,
    SMTP_PASSWORD: process.env.SMTP_PASSWORD,
    FROM_EMAIL: process.env.FROM_EMAIL,
    FROM_NAME: process.env.FROM_NAME,
    
    // File Upload
    MAX_FILE_UPLOAD: process.env.MAX_FILE_UPLOAD || 1000000,
    FILE_UPLOAD_PATH: process.env.FILE_UPLOAD_PATH || 'public/uploads',
    
    // Geocoder
    GEOCODER_PROVIDER: process.env.GEOCODER_PROVIDER,
    GEOCODER_API_KEY: process.env.GEOCODER_API_KEY,
    
    // Frontend URL
    FRONTEND_URL: process.env.FRONTEND_URL,
    
    // Payment Gateway
    STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY,
    STRIPE_WEBHOOK_SECRET: process.env.STRIPE_WEBHOOK_SECRET
};