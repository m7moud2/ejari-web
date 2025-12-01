// controllers/documentsController.js
const Document = require('../models/Document');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/async');
const { upload } = require('../utils/fileUpload');

exports.uploadDocument = asyncHandler(async (req, res, next) => {
    const { type, relatedTo, description } = req.body;

    if (!req.file) {
        return next(new ErrorResponse('الرجاء تحميل ملف', 400));
    }

    const document = await Document.create({
        name: req.file.originalname,
        type,
        relatedTo,
        description,
        file: req.file.path,
        uploadedBy: req.user.id
    });

    res.status(201).json({
        success: true,
        data: document
    });
});

// controllers/reportsController.js
const Property = require('../models/Property');
const Booking = require('../models/Booking');
const Payment = require('../models/Payment');
const asyncHandler = require('../middleware/async');

exports.getFinancialReport = asyncHandler(async (req, res, next) => {
    const { startDate, endDate } = req.query;
    
    // إجمالي الإيرادات
    const payments = await Payment.find({
        status: 'ناجح',
        createdAt: {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
        }
    });

    // إحصائيات الحجوزات
    const bookings = await Booking.find({
        createdAt: {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
        }
    });

    const report = {
        totalRevenue: payments.reduce((acc, payment) => acc + payment.amount, 0),
        totalBookings: bookings.length,
        paymentMethods: {
            cash: payments.filter(p => p.paymentMethod === 'كاش').length,
            card: payments.filter(p => p.paymentMethod === 'بطاقة').length,
            transfer: payments.filter(p => p.paymentMethod === 'تحويل بنكي').length
        },
        bookingStatus: {
            pending: bookings.filter(b => b.status === 'معلق').length,
            confirmed: bookings.filter(b => b.status === 'مؤكد').length,
            cancelled: bookings.filter(b => b.status === 'ملغي').length
        },
        period: {
            startDate,
            endDate
        }
    };

    res.status(200).json({
        success: true,
        data: report
    });
});

exports.getPropertyReport = asyncHandler(async (req, res, next) => {
    const propertyId = req.params.id;
    const { startDate, endDate } = req.query;

    const property = await Property.findById(propertyId);
    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }

    // الحجوزات والمدفوعات المتعلقة بالعقار
    const bookings = await Booking.find({
        property: propertyId,
        createdAt: {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
        }
    });

    const bookingIds = bookings.map(b => b._id);
    const payments = await Payment.find({
        booking: { $in: bookingIds }
    });

    // حساب معدل الإشغال
    const totalDays = Math.ceil((new Date(endDate) - new Date(startDate)) / (1000 * 60 * 60 * 24));
    const occupiedDays = bookings.reduce((acc, booking) => {
        const days = Math.ceil((new Date(booking.endDate) - new Date(booking.startDate)) / (1000 * 60 * 60 * 24));
        return acc + days;
    }, 0);

    const report = {
        property: {
            id: property._id,
            title: property.title,
            type: property.type
        },
        occupancyRate: (occupiedDays / totalDays) * 100,
        totalBookings: bookings.length,
        totalRevenue: payments.reduce((acc, payment) => acc + payment.amount, 0),
        averageBookingDuration: occupiedDays / bookings.length || 0,
        maintenanceRequests: await Maintenance.countDocuments({
            property: propertyId,
            createdAt: {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            }
        }),
        period: {
            startDate,
            endDate
        }
    };

    res.status(200).json({
        success: true,
        data: report
    });
});