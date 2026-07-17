const mongoose = require('mongoose');

const maintenanceSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: true
    },
    property: {
        type: mongoose.Schema.ObjectId,
        ref: 'Property',
        required: true
    },
    type: {
        type: String,
        required: [true, 'الرجاء تحديد نوع الصيانة'],
        enum: ['plumbing', 'electricity', 'air-conditioning', 'cleaning', 'painting', 'other']
    },
    description: {
        type: String,
        required: [true, 'الرجاء إدخال وصف للمشكلة']
    },
    status: {
        type: String,
        enum: ['pending', 'in-progress', 'completed'],
        default: 'pending'
    },
    notes: [{
        text: {
            type: String,
            required: true
        },
        user: {
            type: mongoose.Schema.ObjectId,
            ref: 'User',
            required: true
        },
        createdAt: {
            type: Date,
            default: Date.now
        }
    }],
    cost: {
        type: Number,
        default: 0
    },
    rating: {
        score: {
            type: Number,
            min: 1,
            max: 5
        },
        comment: String
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Maintenance', maintenanceSchema);
