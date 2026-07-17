const Booking = require('../models/Booking');
const Property = require('../models/Property');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/async');
const sendEmail = require('../utils/email');

// @desc      إنشاء حجز جديد
// @route     POST /api/bookings
// @access    Private
exports.createBooking = asyncHandler(async (req, res, next) => {
    req.body.user = req.user.id;
    
    const property = await Property.findById(req.body.property);
    
    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }
    
    // التحقق من توفر العقار
    if (property.status !== 'متاح') {
        return next(new ErrorResponse('العقار غير متاح للحجز حالياً', 400));
    }
    
    // التحقق من تداخل التواريخ
    const existingBooking = await Booking.findOne({
        property: property._id,
        status: { $in: ['معلق', 'مؤكد'] },
        $or: [
            {
                startDate: { $lte: req.body.startDate },
                endDate: { $gte: req.body.startDate }
            },
            {
                startDate: { $lte: req.body.endDate },
                endDate: { $gte: req.body.endDate }
            }
        ]
    });
    
    if (existingBooking) {
        return next(new ErrorResponse('العقار محجوز في هذه الفترة', 400));
    }
    
    // حساب السعر الإجمالي
    const startDate = new Date(req.body.startDate);
    const endDate = new Date(req.body.endDate);
    const days = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
    req.body.totalPrice = days * property.price;
    
    const booking = await Booking.create(req.body);
    
    // إرسال إيميل تأكيد للمستخدم
    await sendEmail({
        email: req.user.email,
        subject: 'تأكيد الحجز',
        message: `تم استلام طلب حجزك رقم ${booking.contractNumber} بنجاح. سيتم مراجعة الطلب والرد عليك في أقرب وقت.`
    });
    
    // إرسال إشعار للمالك
    await sendEmail({
        email: property.owner.email,
        subject: 'طلب حجز جديد',
        message: `لديك طلب حجز جديد للعقار ${property.title}. رقم الحجز: ${booking.contractNumber}`
    });
    
    res.status(201).json({
        success: true,
        data: booking
    });
});

// @desc      الحصول على جميع الحجوزات
// @route     GET /api/bookings
// @access    Private
exports.getBookings = asyncHandler(async (req, res, next) => {
    let query;
    
    // إذا كان المستخدم admin يمكنه رؤية جميع الحجوزات
    if (req.user.role === 'admin') {
        query = Booking.find();
    } else if (req.user.role === 'owner') {
        // المالك يرى الحجوزات الخاصة بعقاراته
        const properties = await Property.find({ owner: req.user.id });
        const propertyIds = properties.map(prop => prop._id);
        query = Booking.find({ property: { $in: propertyIds } });
    } else {
        // المستخدم العادي يرى حجوزاته فقط
        query = Booking.find({ user: req.user.id });
    }
    
    // Populate
    query = query.populate([
        {
            path: 'property',
            select: 'title location price images'
        },
        {
            path: 'user',
            select: 'name email phone'
        }
    ]);
    
    const bookings = await query;
    
    res.status(200).json({
        success: true,
        count: bookings.length,
        data: bookings
    });
});

// @desc      تحديث حالة الحجز
// @route     PUT /api/bookings/:id/status
// @access    Private
exports.updateBookingStatus = asyncHandler(async (req, res, next) => {
    const { status } = req.body;
    
    const booking = await Booking.findById(req.params.id);
    
    if (!booking) {
        return next(new ErrorResponse('الحجز غير موجود', 404));
    }
    
    // التحقق من الصلاحيات
    const property = await Property.findById(booking.property);
    if (property.owner.toString() !== req.user.id && req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بتحديث هذا الحجز', 401));
    }
    
    booking.status = status;
    await booking.save();
    
    // إرسال إشعار للمستخدم
    await sendEmail({
        email: booking.user.email,
        subject: 'تحديث حالة الحجز',
        message: `تم تحديث حالة حجزك رقم ${booking.contractNumber} إلى ${status}`
    });
    
    res.status(200).json({
        success: true,
        data: booking
    });
});
// @desc      الحصول على تفاصيل حجز معين
// exports.getBooking
exports.getBooking = asyncHandler(async (req, res, next) => {
    const booking = await Booking.findById(req.params.id)
        .populate({
            path: 'property',
            select: 'title location price images owner'
        })
        .populate({
            path: 'user',
            select: 'name email phone'
        });

    if (!booking) {
        return next(new ErrorResponse('الحجز غير موجود', 404));
    }

    // التحقق من الصلاحيات (المستأجر، المالك، أو الأدمن)
    if (
        booking.user._id.toString() !== req.user.id &&
        booking.property.owner.toString() !== req.user.id &&
        req.user.role !== 'admin'
    ) {
        return next(new ErrorResponse('غير مصرح لك بعرض هذا الحجز', 401));
    }

    res.status(200).json({
        success: true,
        data: booking
    });
});

// @desc      حذف حجز
// exports.deleteBooking
exports.deleteBooking = asyncHandler(async (req, res, next) => {
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
        return next(new ErrorResponse('الحجز غير موجود', 404));
    }

    // التحقق من الصلاحيات (الأدمن فقط)
    if (req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بحذف هذا الحجز', 403));
    }

    await booking.deleteOne();

    res.status(200).json({
        success: true,
        data: {}
    });
});

// @desc      الحصول على حجوزات عقار معين
// exports.getBookingsByProperty
exports.getBookingsByProperty = asyncHandler(async (req, res, next) => {
    const bookings = await Booking.find({ property: req.params.propertyId })
        .populate({
            path: 'property',
            select: 'title'
        })
        .populate({
            path: 'user',
            select: 'name email phone'
        });

    res.status(200).json({
        success: true,
        count: bookings.length,
        data: bookings
    });
});