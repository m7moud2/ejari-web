const NodeGeocoder = require('node-geocoder');

const options = {
    provider: process.env.GEOCODER_PROVIDER || 'openstreetmap',
    apiKey: process.env.GEOCODER_API_KEY || ''
};

// Fallback to openstreetmap if provider needs an API key but none is configured
if ((options.provider === 'mapquest' || options.provider === 'google') && !options.apiKey) {
    options.provider = 'openstreetmap';
}

const geocoder = NodeGeocoder(options);

module.exports = geocoder;
