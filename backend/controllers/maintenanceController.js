const Maintenance = require('../models/Maintenance');
const Property = require('../models/Property');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/async');
const sendEmail = require('../utils/sendEmail');

// @desc      إنشاء طلب صيانة جديد
// @route     POST /api/maintenance
// @access    Private
exports.createMaintenanceRequest = asyncHandler(async (req, res, next) => {
    const property = await Property.findById(req.body.property);

    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }

    // التحقق من أن المستخدم مستأجر لهذا العقار
    const isRenter = await Booking.findOne({
        property: property._id,
        user: req.user.id,
        status: 'مؤكد'
    });

    if (!isRenter && req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بإنشاء طلب صيانة لهذا العقار', 403));
    }

    const maintenance = await Maintenance.create({
        ...req.body,
        user: req.user.id
    });

    // إرسال إشعار للمالك
    const ownerEmail = await User.findById(property.owner).select('email');
    await sendEmail({
        email: ownerEmail.email,
        subject: 'طلب صيانة جديد',
        message: `تم تقديم طلب صيانة جديد للعقار ${property.title}. نوع المشكلة: ${maintenance.type}`
    });

    res.status(201).json({
        success: true,
        data: maintenance
    });
});

// @desc      الحصول على جميع طلبات الصيانة
// @route     GET /api/maintenance
// @access    Private
exports.getMaintenanceRequests = asyncHandler(async (req, res, next) => {
    let query;

    if (req.user.role === 'admin') {
        query = Maintenance.find();
    } else if (req.user.role === 'owner') {
        const properties = await Property.find({ owner: req.user.id });
        const propertyIds = properties.map(prop => prop._id);
        query = Maintenance.find({ property: { $in: propertyIds } });
    } else {
        query = Maintenance.find({ user: req.user.id });
    }

    const maintenanceRequests = await query.populate([
        {
            path: 'property',
            select: 'title location'
        },
        {
            path: 'user',
            select: 'name email phone'
        }
    ]);

    res.status(200).json({
        success: true,
        count: maintenanceRequests.length,
        data: maintenanceRequests
    });
});

// @desc      تحديث حالة طلب الصيانة
// @route     PUT /api/maintenance/:id
// @access    Private
exports.updateMaintenanceStatus = asyncHandler(async (req, res, next) => {
    let maintenance = await Maintenance.findById(req.params.id);

    if (!maintenance) {
        return next(new ErrorResponse('طلب الصيانة غير موجود', 404));
    }

    // التحقق من الصلاحيات
    const property = await Property.findById(maintenance.property);
    if (property.owner.toString() !== req.user.id && req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بتحديث هذا الطلب', 403));
    }

    maintenance.status = req.body.status;
    if (req.body.notes) {
        maintenance.notes.push({
            text: req.body.notes,
            user: req.user.id
        });
    }

    if (req.body.cost) {
        maintenance.cost = req.body.cost;
    }

    maintenance = await maintenance.save();

    // إرسال إشعار للمستأجر
    const userEmail = await User.findById(maintenance.user).select('email');
    await sendEmail({
        email: userEmail.email,
        subject: 'تحديث طلب الصيانة',
        message: `تم تحديث حالة طلب الصيانة الخاص بك إلى: ${maintenance.status}`
    });

    res.status(200).json({
        success: true,
        data: maintenance
    });
});

// @desc      إضافة تقييم لطلب الصيانة
// @route     POST /api/maintenance/:id/rating
// @access    Private
exports.addMaintenanceRating = asyncHandler(async (req, res, next) => {
    const maintenance = await Maintenance.findById(req.params.id);

    if (!maintenance) {
        return next(new ErrorResponse('طلب الصيانة غير موجود', 404));
    }

    // التحقق من أن المستخدم هو من قدم الطلب
    if (maintenance.user.toString() !== req.user.id) {
        return next(new ErrorResponse('غير مصرح لك بتقييم هذا الطلب', 403));
    }

    maintenance.rating = {
        score: req.body.score,
        comment: req.body.comment
    };

    await maintenance.save();

    res.status(200).json({
        success: true,
        data: maintenance
    });
});