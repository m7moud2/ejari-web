// authRoutes.js
const express = require('express');
const {
    register,
    login,
    logout,
    getMe,
    updateDetails,
    updatePassword,
    forgotPassword,
    resetPassword
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);
router.get('/logout', logout);
router.get('/me', protect, getMe);
router.put('/updatedetails', protect, updateDetails);
router.put('/updatepassword', protect, updatePassword);
router.post('/forgotpassword', forgotPassword);
router.put('/resetpassword/:resettoken', resetPassword);

module.exports = router;

// propertyRoutes.js
const express = require('express');
const {
    getProperties,
    getProperty,
    createProperty,
    updateProperty,
    deleteProperty,
    getPropertiesInRadius,
    propertyPhotoUpload
} = require('../controllers/propertyController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
    .get(getProperties)
    .post(protect, authorize('owner', 'admin'), createProperty);

router.route('/radius/:zipcode/:distance')
    .get(getPropertiesInRadius);

router.route('/:id')
    .get(getProperty)
    .put(protect, authorize('owner', 'admin'), updateProperty)
    .delete(protect, authorize('owner', 'admin'), deleteProperty);

router.route('/:id/photo')
    .put(protect, authorize('owner', 'admin'), propertyPhotoUpload);

module.exports = router;

// bookingRoutes.js
const express = require('express');
const router = express.Router();
const {
    createBooking,
    getBookings,
    getBooking,
    updateBookingStatus,
    deleteBooking,
    getBookingsByProperty
} = require('../controllers/bookingController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
    .get(protect, getBookings)
    .post(protect, createBooking);

router.route('/:id')
    .get(protect, getBooking)
    .delete(protect, authorize('admin'), deleteBooking);

router.route('/:id/status')
    .put(protect, authorize('owner', 'admin'), updateBookingStatus);

router.route('/property/:propertyId')
    .get(protect, authorize('owner', 'admin'), getBookingsByProperty);

module.exports = router;const jwt = require('jsonwebtoken');
const asyncHandler = require('./async');
const ErrorResponse = require('../utils/errorResponse');
const User = require('../models/User');

// حماية المسارات
exports.protect = asyncHandler(async (req, res, next) => {
    let token;

    // التحقق من وجود التوكن في الهيدر
    if (req.headers.authorization && 
        req.headers.authorization.startsWith('Bearer')
    ) {
        token = req.headers.authorization.split(' ')[1];
    } 
    // التحقق من وجود التوكن في الكوكيز
    else if (req.cookies.token) {
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
        next();
    } catch (err) {
        return next(new ErrorResponse('غير مصرح لك بالوصول لهذا المسار', 401));
    }
});

// التحقق من الصلاحيات
exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return next(
                new ErrorResponse(
                    `دور المستخدم ${req.user.role} غير مصرح له بالوصول لهذا المسار`,
                    403
                )
            );
        }
        next();
    };
};

// التحقق من ملكية العقار
exports.checkPropertyOwnership = asyncHandler(async (req, res, next) => {
    const property = await Property.findById(req.params.id);
    
    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }

    if (property.owner.toString() !== req.user.id && req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بالوصول لهذا العقار', 403));
    }

    next();
});