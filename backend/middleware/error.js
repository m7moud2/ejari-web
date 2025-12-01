const ErrorResponse = require('../utils/errorResponse');

const errorHandler = (err, req, res, next) => {
    let error = { ...err };
    error.message = err.message;

    // خطأ في الـ ID
    if (err.name === 'CastError') {
        const message = 'المعرف غير صحيح';
        error = new ErrorResponse(message, 404);
    }

    // خطأ في القيم المكررة
    if (err.code === 11000) {
        const message = 'تم إدخال قيمة مكررة';
        error = new ErrorResponse(message, 400);
    }

    // خطأ في التحقق
    if (err.name === 'ValidationError') {
        const message = Object.values(err.errors).map(val => val.message);
        error = new ErrorResponse(message, 400);
    }

    res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'خطأ في الخادم'
    });
};

module.exports = errorHandler;