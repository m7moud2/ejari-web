const Payment = require('../models/Payment');
const Booking = require('../models/Booking');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/async');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

// @desc      إنشاء جلسة دفع جديدة
// @route     POST /api/payments/create-session
// @access    Private
exports.createPaymentSession = asyncHandler(async (req, res, next) => {
    const booking = await Booking.findById(req.body.bookingId)
        .populate('property')
        .populate('user');

    if (!booking) {
        return next(new ErrorResponse('الحجز غير موجود', 404));
    }

    // إنشاء جلسة Stripe
    const session = await stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        customer_email: req.user.email,
        line_items: [{
            price_data: {
                currency: 'egp',
                unit_amount: booking.totalPrice * 100, // تحويل إلى بيسات
                product_data: {
                    name: `حجز ${booking.property.title}`,
                    description: `من ${booking.startDate} إلى ${booking.endDate}`,
                },
            },
            quantity: 1,
        }],
        mode: 'payment',
        success_url: `${process.env.FRONTEND_URL}/bookings/${booking._id}/success`,
        cancel_url: `${process.env.FRONTEND_URL}/bookings/${booking._id}/cancel`,
        metadata: {
            bookingId: booking._id.toString(),
            userId: req.user._id.toString()
        }
    });

    res.status(200).json({
        success: true,
        sessionId: session.id
    });
});

// @desc      معالجة webhook من Stripe
// @route     POST /api/payments/webhook
// @access    Public
exports.stripeWebhook = asyncHandler(async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event;

    try {
        event = stripe.webhooks.constructEvent(
            req.body,
            sig,
            process.env.STRIPE_WEBHOOK_SECRET
        );
    } catch (err) {
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // معالجة الدفع الناجح
    if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        
        // تحديث حالة الحجز والدفع
        const booking = await Booking.findById(session.metadata.bookingId);
        booking.paymentStatus = 'مدفوع';
        booking.status = 'مؤكد';
        await booking.save();

        // إنشاء سجل الدفع
        await Payment.create({
            booking: session.metadata.bookingId,
            user: session.metadata.userId,
            amount: session.amount_total / 100,
            paymentMethod: 'بطاقة',
            transactionId: session.payment_intent,
            status: 'ناجح'
        });
    }

    res.json({ received: true });
});

// @desc      الحصول على سجلات الدفع للمستخدم
// @route     GET /api/payments
// @access    Private
exports.getPayments = asyncHandler(async (req, res, next) => {
    const payments = await Payment.find({ user: req.user.id })
        .populate({
            path: 'booking',
            populate: {
                path: 'property',
                select: 'title'
            }
        });

    res.status(200).json({
        success: true,
        count: payments.length,
        data: payments
    });
});

// @desc      استرداد المبلغ
// @route     POST /api/payments/:id/refund
// @access    Private (Admin)
exports.refundPayment = asyncHandler(async (req, res, next) => {
    const payment = await Payment.findById(req.params.id);

    if (!payment) {
        return next(new ErrorResponse('الدفع غير موجود', 404));
    }

    // التحقق من إمكانية الاسترداد
    if (payment.status !== 'ناجح') {
        return next(new ErrorResponse('لا يمكن استرداد هذا المبلغ', 400));
    }

    // إنشاء استرداد في Stripe
    const refund = await stripe.refunds.create({
        payment_intent: payment.transactionId,
        reason: req.body.reason
    });

    // تحديث سجل الدفع
    payment.status = 'مسترد';
    payment.refundId = refund.id;
    await payment.save();

    // تحديث حالة الحجز
    const booking = await Booking.findById(payment.booking);
    booking.paymentStatus = 'مسترد';
    booking.status = 'ملغي';
    await booking.save();

    res.status(200).json({
        success: true,
        data: payment
    });
});