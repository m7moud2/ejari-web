const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: true
    },
    title: {
        type: String,
        required: true
    },
    message: {
        type: String,
        required: true
    },
    type: {
        type: String,
        enum: ['عام', 'حجز', 'دفع', 'صيانة', 'رسالة', 'تقييم'],
        required: true
    },
    relatedTo: {
        model: {
            type: String,
            enum: ['Booking', 'Payment', 'Maintenance', 'Message', 'Property']
        },
        id: {
            type: mongoose.Schema.ObjectId
        }
    },
    isRead: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Notification', notificationSchema);