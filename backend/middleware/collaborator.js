const Trip = require('../models/trip');

const collaboratorMiddleware = (tripIdSource = 'body') => {
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

      // Find the trip and check if user has access
      const trip = await Trip.findById(tripId);
      
      if (!trip) {
        return res.status(404).json({
          success: false,
          message: 'Trip not found'
        });
      }

      // Check if the authenticated user is the owner
      const isOwner = trip.user.toString() === req.user._id.toString();
      
      // Check if the authenticated user is a collaborator
      const isCollaborator = trip.collaborators && 
        trip.collaborators.some(collaboratorId => 
          collaboratorId.toString() === req.user._id.toString()
        );

      // Allow access if user is owner or collaborator
      if (!isOwner && !isCollaborator) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. You must be the trip owner or a collaborator to perform this action'
        });
      }

      // Add trip and user role to request object for use in subsequent middleware/routes
      req.trip = trip;
      req.userRole = isOwner ? 'owner' : 'collaborator';
      next();
      
    } catch (error) {
      console.error('Collaborator middleware error:', error);
      return res.status(500).json({
        success: false,
        message: 'Internal server error in collaborator validation'
      });
    }
  };
};

module.exports = collaboratorMiddleware; 