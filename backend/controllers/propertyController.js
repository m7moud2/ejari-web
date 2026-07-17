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
    
    await property.deleteOne();
    
    res.status(200).json({
        success: true,
        data: {}
    });
});

// @desc      الحصول على عقار معين
// @route     GET /api/properties/:id
// @access    Public
exports.getProperty = asyncHandler(async (req, res, next) => {
    const property = await Property.findById(req.params.id).populate({
        path: 'owner',
        select: 'name email phone'
    });

    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }

    res.status(200).json({
        success: true,
        data: property
    });
});

// @desc      البحث عن العقارات في نطاق معين
// @route     GET /api/properties/radius/:zipcode/:distance
// @access    Public
exports.getPropertiesInRadius = asyncHandler(async (req, res, next) => {
    const { zipcode, distance } = req.params;

    const loc = await geocoder.geocode(zipcode);
    if (!loc || loc.length === 0) {
        return next(new ErrorResponse('الرمز البريدي غير صحيح', 400));
    }
    const lat = loc[0].latitude;
    const lng = loc[0].longitude;

    // نصف قطر الأرض بالـ ميل = 3963، بالـ كم = 6378
    const radius = distance / 6378;

    const properties = await Property.find({
        'location.coordinates': { $geoWithin: { $centerSphere: [[lng, lat], radius] } }
    });

    res.status(200).json({
        success: true,
        count: properties.length,
        data: properties
    });
});

// @desc      رفع صورة للعقار
// @route     PUT /api/properties/:id/photo
// @access    Private
exports.propertyPhotoUpload = asyncHandler(async (req, res, next) => {
    const path = require('path');
    const property = await Property.findById(req.params.id);

    if (!property) {
        return next(new ErrorResponse('العقار غير موجود', 404));
    }

    // التأكد من ملكية العقار
    if (property.owner.toString() !== req.user.id && req.user.role !== 'admin') {
        return next(new ErrorResponse('غير مصرح لك بتحديث هذا العقار', 401));
    }

    if (!req.files) {
        return next(new ErrorResponse('الرجاء رفع ملف صورة', 400));
    }

    const file = req.files.file;

    // التحقق من أنه ملف صورة
    if (!file.mimetype.startsWith('image')) {
        return next(new ErrorResponse('الرجاء رفع ملف صورة فقط', 400));
    }

    // التحقق من حجم الملف
    const maxFileSize = process.env.MAX_FILE_SIZE || 5242880;
    if (file.size > maxFileSize) {
        return next(new ErrorResponse('حجم الملف كبير جداً', 400));
    }

    // إنشاء اسم فريد للملف
    file.name = `photo_${property._id}${path.parse(file.name).ext}`;

    const uploadPath = process.env.UPLOAD_PATH || './uploads';
    file.mv(`${uploadPath}/${file.name}`, async err => {
        if (err) {
            console.error(err);
            return next(new ErrorResponse('مشكلة في رفع الملف', 500));
        }

        await Property.findByIdAndUpdate(req.params.id, { $push: { images: file.name } });

        res.status(200).json({
            success: true,
            data: file.name
        });
    });
});