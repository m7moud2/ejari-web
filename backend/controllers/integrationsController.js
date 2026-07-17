const { geocodeAddress, searchLocation, createMapBootConfig } = require('../services/apiIntegrations');

exports.getMapConfig = (req, res) => {
  res.json({ success: true, data: createMapBootConfig() });
};

exports.geocode = async (req, res, next) => {
  try {
    const { address } = req.query;
    const result = await geocodeAddress(address);
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

exports.searchLocation = async (req, res, next) => {
  try {
    const { q } = req.query;
    const result = await searchLocation(q);
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};
