const express = require('express');
const router = express.Router();
const {
    getProperties,
    getProperty,
    createProperty,
    updateProperty,
    deleteProperty,
    getPropertiesInRadius,
    propertyPhotoUpload
} = require('../controllers/propertyController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
    .get(getProperties)
    .post(protect, authorize('owner', 'admin'), createProperty);

router.route('/radius/:zipcode/:distance')
    .get(getPropertiesInRadius);

router.route('/:id')
    .get(getProperty)
    .put(protect, authorize('owner', 'admin'), updateProperty)
    .delete(protect, authorize('owner', 'admin'), deleteProperty);

router.route('/:id/photo')
    .put(protect, authorize('owner', 'admin'), propertyPhotoUpload);

module.exports = router;
