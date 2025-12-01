const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
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
    startDate: {
        type: Date,
        required: [true, 'الرجاء تحديد تاريخ بداية الإيجار']
    },
    endDate: {
        type: Date,
        required: [true, 'الرجاء تحديد تاريخ نهاية الإيجار']
    },
    totalPrice: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['معلق', 'مؤكد', 'ملغي', 'منتهي'],
        default: 'معلق'
    },
    paymentStatus: {
        type: String,
        enum: ['معلق', 'مدفوع', 'مسترد'],
        default: 'معلق'
    },
    paymentMethod: {
        type: String,
        enum: ['كاش', 'بطاقة ائتمان', 'تحويل بنكي'],
        required: true
    },
    contractNumber: {
        type: String,
        unique: true
    },
    specialRequests: String,
    documents: [{
        type: String
    }],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Pre-save hook لإنشاء رقم العقد
bookingSchema.pre('save', async function(next) {
    if (!this.contractNumber) {
        const date = new Date();
        const year = date.getFullYear();
        const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
        this.contractNumber = `EJ-${year}-${random}`;
    }
    next();
});

module.exports = mongoose.model('Booking', bookingSchema);