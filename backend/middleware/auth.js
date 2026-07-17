const jwt = require('jsonwebtoken');
const asyncHandler = require('./async');
const ErrorResponse = require('../utils/errorResponse');
const User = require('../models/User');

// حماية المسارات (Protect Routes)
exports.protect = asyncHandler(async (req, res, next) => {
    let token;

    // التحقق من وجود التوكن في الهيدر
    if (req.headers.authorization && 
        req.headers.authorization.startsWith('Bearer')
    ) {
        token = req.headers.authorization.split(' ')[1];
    } 
    // التحقق من وجود التوكن في الكوكيز
    else if (req.cookies && req.cookies.token) {
        token = req.cookies.token;
    }

    // التأكد من وجود التوكن
    if (!token) {
        return next(new ErrorResponse('غير مصرح لك بالوصول لهذا المسار', 401));
    }

    try {
        // التحقق من التوكن
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // إضافة المستخدم للريكويست
        req.user = await User.findById(decoded.id);
        if (!req.user) {
            return next(new ErrorResponse('المستخدم صاحب هذا التوكن لم يعد موجوداً', 404));
        }
        next();
    } catch (err) {
        return next(new ErrorResponse('غير مصرح لك بالوصول لهذا المسار', 401));
    }
});

// التحقق من الصلاحيات (Authorize Roles)
exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user || !roles.includes(req.user.role)) {
            return next(
                new ErrorResponse(
                    `دور المستخدم ${req.user ? req.user.role : 'غير معروف'} غير مصرح له بالوصول لهذا المسار`,
                    403
                )
            );
        }
        next();
    };
};

// التحقق من ملكية العقار (Check Property Ownership)
exports.checkPropertyOwnership = asyncHandler(async (req, res, next) => {
    const Property = require('../models/Property');
    const property = await Property.findById(req.params.id);
    
    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }

    if (property.owner.toString() !== req.user.id && req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بالوصول لهذا العقار', 403));
    }

    next();
});
