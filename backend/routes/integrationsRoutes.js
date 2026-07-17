const express = require('express');
const router = express.Router();
const { getMapConfig, geocode, searchLocation } = require('../controllers/integrationsController');

router.get('/map-config', getMapConfig);
router.get('/geocode', geocode);
router.get('/search-location', searchLocation);

module.exports = router;
