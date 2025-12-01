const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    conversation: {
        type: mongoose.Schema.ObjectId,
        ref: 'Conversation',
        required: true
    },
    sender: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: true
    },
    content: {
        type: String,
        required: [true, 'الرجاء إدخال محتوى الرسالة']
    },
    attachments: [{
        type: String
    }],
    isRead: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});