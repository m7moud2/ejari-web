const express = require('express');
const router = express.Router();
const {
    createBooking,
    getBookings,
    getBooking,
    updateBookingStatus,
    deleteBooking,
    getBookingsByProperty
} = require('../controllers/bookingController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
    .get(protect, getBookings)
    .post(protect, createBooking);

router.route('/:id')
    .get(protect, getBooking)
    .delete(protect, authorize('admin'), deleteBooking);

router.route('/:id/status')
    .put(protect, authorize('owner', 'admin'), updateBookingStatus);

router.route('/property/:propertyId')
    .get(protect, authorize('owner', 'admin'), getBookingsByProperty);

module.exports = router;
