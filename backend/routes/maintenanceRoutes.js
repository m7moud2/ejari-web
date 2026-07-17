const express = require('express');
const router = express.Router();
const {
    createMaintenanceRequest,
    getMaintenanceRequests,
    updateMaintenanceStatus,
    addMaintenanceRating
} = require('../controllers/maintenanceController');
const { protect } = require('../middleware/auth');

router.route('/')
    .get(protect, getMaintenanceRequests)
    .post(protect, createMaintenanceRequest);

router.route('/:id')
    .put(protect, updateMaintenanceStatus);

router.route('/:id/rating')
    .post(protect, addMaintenanceRating);

module.exports = router;
