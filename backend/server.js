// server.js

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const xss = require('xss-clean');
const mongoSanitize = require('express-mongo-sanitize');
const fileUpload = require('express-fileupload');

dotenv.config();

const app = express();

// Middleware
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(helmet());
app.use(xss());
app.use(mongoSanitize());
app.use(fileUpload());
app.use(morgan('dev'));

// Rate limiting
const limiter = rateLimit({
    max: 100, // عدد الطلبات المسموح بها
    windowMs: 60 * 60 * 1000, // 1 ساعة
    message: 'عدد كبير من الطلبات من نفس الـ IP، برجاء المحاولة لاحقاً'
});
app.use('/api', limiter);

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/properties', require('./routes/propertyRoutes'));
app.use('/api/bookings', require('./routes/bookingRoutes'));
app.use('/api/payments', require('./routes/paymentRoutes'));
app.use('/api/maintenance', require('./routes/maintenanceRoutes'));
app.use('/api/ai', require('./routes/aiRoutes'));
app.use('/api/integrations', require('./routes/integrationsRoutes'));

// Error handling
app.use(require('./middleware/error'));

const seedData = require('./utils/seeder');

// Database connection
mongoose.connect(process.env.MONGODB_URI)
    .then(async () => {
        console.log('تم الاتصال بقاعدة البيانات بنجاح');
        await seedData();
    })
    .catch((err) => console.error('خطأ في الاتصال بقاعدة البيانات:', err));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

module.exports = app;