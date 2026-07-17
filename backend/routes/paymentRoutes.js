const express = require('express');
const router = express.Router();
const {
    createPaymentSession,
    stripeWebhook,
    getPayments,
    refundPayment
} = require('../controllers/paymentController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
    .get(protect, getPayments);

router.post('/create-session', protect, createPaymentSession);
router.post('/webhook', stripeWebhook);
router.post('/:id/refund', protect, authorize('admin'), refundPayment);

module.exports = router;
