const Notification = require('../models/Notification');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/async');
const io = require('../utils/socket').getIO();

exports.sendNotification = asyncHandler(async (userId, data) => {
    const notification = await Notification.create({
        user: userId,
        ...data
    });

    io.to(`user_${userId}`).emit('notification', notification);
    return notification;
});

exports.getNotifications = asyncHandler(async (req, res, next) => {
    const notifications = await Notification.find({ user: req.user.id })
        .sort('-createdAt')
        .limit(50);

    res.status(200).json({
        success: true,
        count: notifications.length,
        data: notifications
    });
});

exports.markAsRead = asyncHandler(async (req, res, next) => {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
        return next(new ErrorResponse('الإشعار غير موجود', 404));
    }

    if (notification.user.toString() !== req.user.id) {
        return next(new ErrorResponse('غير مصرح لك بتحديث هذا الإشعار', 403));
    }

    notification.isRead = true;
    await notification.save();

    res.status(200).json({
        success: true,
        data: notification
    });
});