// models/User.js

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'الرجاء إدخال الاسم'],
        trim: true
    },
    email: {
        type: String,
        required: [true, 'الرجاء إدخال البريد الإلكتروني'],
        unique: true,
        lowercase: true,
        match: [/^\S+@\S+\.\S+$/, 'الرجاء إدخال بريد إلكتروني صحيح']
    },
    password: {
        type: String,
        required: [true, 'الرجاء إدخال كلمة المرور'],
        minlength: [6, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'],
        select: false
    },
    role: {
        type: String,
        enum: ['tenant', 'owner', 'admin'],
        default: 'tenant'
    },
    phone: {
        type: String,
        required: [true, 'الرجاء إدخال رقم الهاتف']
    },
    address: {
        type: String,
        required: [true, 'الرجاء إدخال العنوان']
    },
    avatar: {
        type: String,
        default: 'default.jpg'
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    verificationToken: String,
    verificationTokenExpires: Date,
    resetPasswordToken: String,
    resetPasswordExpires: Date,
    createdAt: {
        type: Date,
        default: Date.now
    },
    favorites: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Property'
    }],
    notifications: [{
        title: String,
        message: String,
        type: String,
        isRead: {
            type: Boolean,
            default: false
        },
        createdAt: {
            type: Date,
            default: Date.now
        }
    }]
});

// تشفير كلمة المرور قبل الحفظ
userSchema.pre('save', async function(next) {
    if (!this.isModified('password')) return next();
    
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
});

// مقارنة كلمة المرور
userSchema.methods.matchPassword = async function(enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

// إنشاء توكن
userSchema.methods.generateAuthToken = function() {
    return jwt.sign(
        { id: this._id },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRE }
    );
};

// إنشاء توكن إعادة تعيين كلمة المرور
userSchema.methods.getResetPasswordToken = function() {
    const resetToken = crypto.randomBytes(20).toString('hex');
    
    this.resetPasswordToken = crypto
        .createHash('sha256')
        .update(resetToken)
        .digest('hex');
    
    this.resetPasswordExpires = Date.now() + 10 * 60 * 1000; // 10 دقائق
    
    return resetToken;
};

module.exports = mongoose.model('User', userSchema);