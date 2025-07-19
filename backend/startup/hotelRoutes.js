const searchByGeoId = require('../routes/hotel/searchByGeoId');

module.exports = function(app) {
  app.use('/api/hotels', searchByGeoId);
};

