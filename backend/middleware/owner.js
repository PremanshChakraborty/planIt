const Trip = require('../models/trip');

const ownerMiddleware = (tripIdSource = 'body') => {
  return async (req, res, next) => {
    try {
      let tripId;
      
      // Extract tripId from different sources based on parameter
      switch (tripIdSource) {
        case 'body':
          tripId = req.body.tripId;
          break;
        case 'params':
          tripId = req.params.tripId || req.params.id;
          break;
        case 'query':
          tripId = req.query.tripId;
          break;
        default:
          tripId = req.body.tripId; // Default to body
      }
      
      if (!tripId) {
        return res.status(400).json({
          success: false,
          message: `Trip ID is required. Expected in ${tripIdSource}`
        });
      }

      // Find the trip and check if user is the owner
      const trip = await Trip.findById(tripId);
      
      if (!trip) {
        return res.status(404).json({
          success: false,
          message: 'Trip not found'
        });
      }

      // Check if the authenticated user is the owner
      if (trip.user.toString() !== req.user._id.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Only trip owner can perform this action'
        });
      }

      // Add trip to request object for use in subsequent middleware/routes
      req.trip = trip;
      next();
      
    } catch (error) {
      console.error('Owner middleware error:', error);
      return res.status(500).json({
        success: false,
        message: 'Internal server error in owner validation'
      });
    }
  };
};

module.exports = ownerMiddleware; 