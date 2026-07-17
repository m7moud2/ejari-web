const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    booking: {
        type: mongoose.Schema.ObjectId,
        ref: 'Booking',
        required: true
    },
    user: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: true
    },
    amount: {
        type: Number,
        required: [true, 'الرجاء إدخال قيمة المبلغ المدفوع']
    },
    paymentMethod: {
        type: String,
        enum: ['كاش', 'بطاقة', 'تحويل بنكي'],
        default: 'بطاقة'
    },
    transactionId: {
        type: String
    },
    status: {
        type: String,
        enum: ['ناجح', 'فاشل', 'مسترد'],
        default: 'ناجح'
    },
    refundId: {
        type: String
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Payment', paymentSchema);
