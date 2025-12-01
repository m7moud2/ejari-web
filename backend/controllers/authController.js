// controllers/authController.js

const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const sendEmail = require('../utils/email');

// @desc    تسجيل مستخدم جديد
// @route   POST /api/auth/register
// @access  Public
exports.register = asyncHandler(async (req, res, next) => {
    const { name, email, password, role, phone } = req.body;

    // إنشاء المستخدم
    const user = await User.create({
        name,
        email,
        password,
        role,
        phone
    });

    // إنشاء توكن التحقق
    const verificationToken = user.getVerificationToken();
    await user.save({ validateBeforeSave: false });

    // إرسال بريد التحقق
    const verificationUrl = `${req.protocol}://${req.get('host')}/api/auth/verify/${verificationToken}`;
    const message = `لتفعيل حسابك، يرجى الضغط على الرابط التالي: ${verificationUrl}`;

    try {
        await sendEmail({
            email: user.email,
            subject: 'تفعيل الحساب',
            message
        });

        sendTokenResponse(user, 200, res);
    } catch (err) {
        user.verificationToken = undefined;
        user.verificationTokenExpires = undefined;
        await user.save({ validateBeforeSave: false });

        return next(new ErrorResponse('لم نتمكن من إرسال بريد التفعيل', 500));
    }
});

// @desc    تسجيل الدخول
// @route   POST /api/auth/login
// @access  Public
exports.login = asyncHandler(async (req, res, next) => {
    const { email, password } = req.body;

    // التحقق من وجود البريد الإلكتروني وكلمة المرور
    if (!email || !password) {
        return next(new ErrorResponse('الرجاء إدخال البريد الإلكتروني وكلمة المرور', 400));
    }

    // التحقق من المستخدم
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
        return next(new ErrorResponse('بيانات الدخول غير صحيحة', 401));
    }

    // التحقق من كلمة المرور
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
        return next(new ErrorResponse('بيانات الدخول غير صحيحة', 401));
    }

    sendTokenResponse(user, 200, res);
});

// @desc    تسجيل الخروج
// @route   GET /api/auth/logout
// @access  Private
exports.logout = asyncHandler(async (req, res, next) => {
    res.cookie('token', 'none', {
        expires: new Date(Date.now() + 10 * 1000),
        httpOnly: true
    });

    res.status(200).json({
        success: true,
        data: {}
    });
});

// @desc    المستخدم الحالي
// @route   GET /api/auth/me
// @access  Private
exports.getMe = asyncHandler(async (req, res, next) => {
    const user = await User.findById(req.user.id);
    res.status(200).json({
        success: true,
        data: user
    });
});

// @desc    تحديث بيانات المستخدم
// @route   PUT /api/auth/updatedetails
// @access  Private
exports.updateDetails = asyncHandler(async (req, res, next) => {
    const fieldsToUpdate = {
        name: req.body.name,
        email: req.body.email,
        phone: req.body.phone
    };

    const user = await User.findByIdAndUpdate(req.user.id, fieldsToUpdate, {
        new: true,
        runValidators: true
    });

    res.status(200).json({
        success: true,
        data: user
    });
});

// @desc    تحديث كلمة المرور
// @route   PUT /api/auth/updatepassword
// @access  Private
exports.updatePassword = asyncHandler(async (req, res, next) => {
    const user = await User.findById(req.user.id).select('+password');

    // التحقق من كلمة المرور الحالية
    if (!(await user.matchPassword(req.body.currentPassword))) {
        return next(new ErrorResponse('كلمة المرور الحالية غير صحيحة', 401));
    }

    user.password = req.body.newPassword;
    await user.save();

    sendTokenResponse(user, 200, res);
});

// @desc    نسيت كلمة المرور
// @route   POST /api/auth/forgotpassword
// @access  Public
exports.forgotPassword = asyncHandler(async (req, res, next) => {
    const user = await User.findOne({ email: req.body.email });

    if (!user) {
        return next(new ErrorResponse('لا يوجد مستخدم بهذا البريد الإلكتروني', 404));
    }

    // إنشاء توكن إعادة تعيين كلمة المرور
    const resetToken = user.getResetPasswordToken();
    await user.save({ validateBeforeSave: false });

    // إنشاء رابط إعادة التعيين
    const resetUrl = `${req.protocol}://${req.get('host')}/api/auth/resetpassword/${resetToken}`;
    const message = `لإعادة تعيين كلمة المرور، يرجى الضغط على الرابط التالي: ${resetUrl}`;

    try {
        await sendEmail({
            email: user.email,
            subject: 'إعادة تعيين كلمة المرور',
            message
        });

        res.status(200).json({ success: true, data: 'تم إرسال البريد الإلكتروني' });
    } catch (err) {
        user.resetPasswordToken = undefined;
        user.resetPasswordExpire = undefined;
        await user.save({ validateBeforeSave: false });

        return next(new ErrorResponse('لم نتمكن من إرسال البريد الإلكتروني', 500));
    }
});

// @desc    إعادة تعيين كلمة المرور
// @route   PUT /api/auth/resetpassword/:resettoken
// @access  Public
exports.resetPassword = asyncHandler(async (req, res, next) => {
    // الحصول على التوكن المشفر
    const resetPasswordToken = crypto
        .createHash('sha256')
        .update(req.params.resettoken)
        .digest('hex');

    const user = await User.findOne({
        resetPasswordToken,
        resetPasswordExpire: { $gt: Date.now() }
    });

    if (!user) {
        return next(new ErrorResponse('رابط غير صالح', 400));
    }

    // تعيين كلمة المرور الجديدة
    user.password = req.body.password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;
    await user.save();

    sendTokenResponse(user, 200, res);
});

// دالة مساعدة لإرسال التوكن في الاستجابة
const sendTokenResponse = (user, statusCode, res) => {
    const token = user.generateAuthToken();

    const options = {
        expires: new Date(Date.now() + process.env.JWT_COOKIE_EXPIRE * 24 * 60 * 60 * 1000),
        httpOnly: true
    };

    if (process.env.NODE_ENV === 'production') {
        options.secure = true;
    }

    res
        .status(statusCode)
        .cookie('token', token, options)
        .json({
            success: true,
            token
        });
};