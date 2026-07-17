const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGODB_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        console.log(`تم الاتصال بقاعدة البيانات بنجاح: ${conn.connection.host}`);
    } catch (err) {
        console.error(`خطأ في الاتصال بقاعدة البيانات: ${err.message}`);
        process.exit(1);
    }
};

module.exports = connectDB;
