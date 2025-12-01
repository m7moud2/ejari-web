const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/async');
const io = require('../utils/socket').getIO();

exports.sendMessage = asyncHandler(async (req, res, next) => {
    const { conversationId, content, attachments } = req.body;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
        return next(new ErrorResponse('المحادثة غير موجودة', 404));
    }

    // التحقق من أن المرسل مشارك في المحادثة
    if (!conversation.participants.includes(req.user.id)) {
        return next(new ErrorResponse('غير مصرح لك بإرسال رسائل في هذه المحادثة', 403));
    }

    const message = await Message.create({
        conversation: conversationId,
        sender: req.user.id,
        content,
        attachments
    });

    // تحديث آخر رسالة في المحادثة
    conversation.lastMessage = message._id;
    await conversation.save();

    // إرسال إشعار للمشاركين الآخرين
    conversation.participants
        .filter(p => p.toString() !== req.user.id)
        .forEach(async (participantId) => {
            io.to(`user_${participantId}`).emit('newMessage', {
                message,
                conversation: conversationId
            });

            // إنشاء إشعار
            await this.sendNotification(participantId, {
                title: 'رسالة جديدة',
                message: `لديك رسالة جديدة من ${req.user.name}`,
                type: 'رسالة',
                relatedTo: {
                    model: 'Message',
                    id: message._id
                }
            });
        });

    res.status(201).json({
        success: true,
        data: message
    });
});

exports.getConversations = asyncHandler(async (req, res, next) => {
    const conversations = await Conversation.find({
        participants: req.user.id
    })
    .populate('participants', 'name avatar')
    .populate('lastMessage')
    .populate('property', 'title')
    .sort('-updatedAt');

    res.status(200).json({
        success: true,
        count: conversations.length,
        data: conversations
    });
});

exports.getMessages = asyncHandler(async (req, res, next) => {
    const { conversationId } = req.params;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
        return next(new ErrorResponse('المحادثة غير موجودة', 404));
    }

    if (!conversation.participants.includes(req.user.id)) {
        return next(new ErrorResponse('غير مصرح لك بعرض هذه المحادثة', 403));
    }

    const messages = await Message.find({ conversation: conversationId })
        .populate('sender', 'name avatar')
        .sort('-createdAt');

    // تحديث حالة القراءة للرسائل
    await Message.updateMany(
        {
            conversation: conversationId,
            sender: { $ne: req.user.id },
            isRead: false
        },
        { isRead: true }
    );

    res.status(200).json({
        success: true,
        count: messages.length,
        data: messages
    });
});