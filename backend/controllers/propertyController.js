const Property = require('../models/Property');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/async');
const geocoder = require('../utils/geocoder');

// @desc      الحصول على جميع العقارات
// @route     GET /api/properties
// @access    Public
exports.getProperties = asyncHandler(async (req, res, next) => {
    // تحضير query
    let query = { ...req.query };
    
    // حذف الحقول الخاصة
    const removeFields = ['select', 'sort', 'page', 'limit'];
    removeFields.forEach(param => delete query[param]);
    
    // إنشاء operators ($gt, $gte, etc)
    let queryStr = JSON.stringify(query);
    queryStr = queryStr.replace(/\b(gt|gte|lt|lte|in)\b/g, match => `$${match}`);
    
    // البحث الأساسي
    query = Property.find(JSON.parse(queryStr));
    
    // Select Fields
    if (req.query.select) {
        const fields = req.query.select.split(',').join(' ');
        query = query.select(fields);
    }
    
    // Sort
    if (req.query.sort) {
        const sortBy = req.query.sort.split(',').join(' ');
        query = query.sort(sortBy);
    } else {
        query = query.sort('-createdAt');
    }
    
    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const total = await Property.countDocuments(JSON.parse(queryStr));
    
    query = query.skip(startIndex).limit(limit);
    
    // تنفيذ Query
    const properties = await query.populate({
        path: 'owner',
        select: 'name email phone'
    });
    
    // Pagination result
    const pagination = {};
    
    if (endIndex < total) {
        pagination.next = {
            page: page + 1,
            limit
        };
    }
    
    if (startIndex > 0) {
        pagination.prev = {
            page: page - 1,
            limit
        };
    }
    
    res.status(200).json({
        success: true,
        count: properties.length,
        pagination,
        data: properties
    });
});

// @desc      إضافة عقار جديد
// @route     POST /api/properties
// @access    Private
exports.createProperty = asyncHandler(async (req, res, next) => {
    // إضافة المالك للعقار
    req.body.owner = req.user.id;
    
    // التحقق من عدد العقارات للمالك
    const publishedProperties = await Property.find({ owner: req.user.id });
    
    // إذا كان المستخدم ليس admin، التحقق من حدود النشر
    if (req.user.role !== 'admin' && publishedProperties.length >= 10) {
        return next(new ErrorResponse('لقد تجاوزت الحد الأقصى لعدد العقارات المسموح به', 400));
    }
    
    // معالجة الموقع
    if (req.body.address) {
        const loc = await geocoder.geocode(req.body.address);
        req.body.location = {
            type: 'Point',
            coordinates: [loc[0].longitude, loc[0].latitude],
            address: loc[0].formattedAddress,
            city: loc[0].city,
            area: loc[0].stateCode
        };
    }
    
    const property = await Property.create(req.body);
    
    res.status(201).json({
        success: true,
        data: property
    });
});

// @desc      تحديث عقار
// @route     PUT /api/properties/:id
// @access    Private
exports.updateProperty = asyncHandler(async (req, res, next) => {
    let property = await Property.findById(req.params.id);
    
    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }
    
    // التأكد من ملكية العقار
    if (property.owner.toString() !== req.user.id && req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بتحديث هذا العقار', 401));
    }
    
    // تحديث الموقع إذا تم تغيير العنوان
    if (req.body.address && req.body.address !== property.location.address) {
        const loc = await geocoder.geocode(req.body.address);
        req.body.location = {
            type: 'Point',
            coordinates: [loc[0].longitude, loc[0].latitude],
            address: loc[0].formattedAddress,
            city: loc[0].city,
            area: loc[0].stateCode
        };
    }
    
    property = await Property.findByIdAndUpdate(req.params.id, req.body, {
        new: true,
        runValidators: true
    });
    
    res.status(200).json({
        success: true,
        data: property
    });
});

// @desc      حذف عقار
// @route     DELETE /api/properties/:id
// @access    Private
exports.deleteProperty = asyncHandler(async (req, res, next) => {
    const property = await Property.findById(req.params.id);
    
    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }
    
    // التأكد من ملكية العقار
    if (property.owner.toString() !== req.user.id && req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بحذف هذا العقار', 401));
    }
    
    await property.remove();
    
    res.status(200).json({
        success: true,
        data: {}
    });
});