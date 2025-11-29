const express = require('express');
const router = express.Router();
const auth = require('../../middleware/auth');
const ownerMiddleware = require('../../middleware/owner');
const collaboratorMiddleware = require('../../middleware/collaborator');
const { User } = require('../../models/user');
const Trip = require('../../models/trip');
const mongoose = require('mongoose');

// GET route: Search users by username/name for adding as collaborators
router.get('/search-users', auth, async (req, res) => {
  try {
    const { query } = req.query;
    
    // Validate search query
    if (!query || query.trim().length < 1) {
      return res.status(400).json({
        success: false,
        message: 'Search query must be at least 1 character long'
      });
    }

    // Search users by name (case-insensitive partial match)
    // Exclude the current authenticated user from search results
    const users = await User.find({
      name: { $regex: query.trim(), $options: 'i' },
      _id: { $ne: req.user._id } // Exclude current user
    })
    .select('_id name email imageUrl') // Only return necessary fields for security
    .limit(20); // Limit results to prevent abuse

    res.status(200).json({
      success: true,
      users: users,
      count: users.length
    });

  } catch (error) {
    console.error('Error searching users:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while searching users'
    });
  }
});

// POST route: Add collaborators to a trip (owners and collaborators can do this)
router.post('/trips/:tripId/collaborators/add', auth, collaboratorMiddleware('params'), async (req, res) => {
  try {
    const { tripId } = req.params;
    const { userIds } = req.body;

    // Validate userIds array
    if (!Array.isArray(userIds)) {
      return res.status(400).json({
        success: false,
        message: 'User IDs must be an array'
      });
    }

    if (userIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'User IDs array cannot be empty'
      });
    }

    // Validate that all user IDs are valid ObjectIds
    const validObjectIds = userIds.every(id => 
      mongoose.Types.ObjectId.isValid(id)
    );
    
    if (!validObjectIds) {
      return res.status(400).json({
        success: false,
        message: 'All user IDs must be valid Object IDs'
      });
    }

    // Use the trip from middleware (already validated access)
    const trip = req.trip;

    // Convert all IDs to ObjectIds for comparison
    const userIdsAsObjectIds = userIds.map(id => new mongoose.Types.ObjectId(id));
    const ownerId = trip.user;
    const existingCollaboratorIds = trip.collaborators || [];

    // Filter out users that are already collaborators or the owner
    const newUserIds = userIdsAsObjectIds.filter(userId => {
      // Exclude if user is the owner
      if (userId.toString() === ownerId.toString()) {
        return false;
      }
      // Exclude if user is already a collaborator
      return !existingCollaboratorIds.some(existingId => 
        existingId.toString() === userId.toString()
      );
    });

    if (newUserIds.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'No new collaborators to add. All users are already collaborators or the owner.',
        count: 0
      });
    }

    // Validate that all new user IDs correspond to existing users
    const existingUsers = await User.find({
      _id: { $in: newUserIds }
    }).select('_id');

    const existingUserIds = existingUsers.map(user => user._id.toString());
    const validNewUserIds = newUserIds.filter(userId => 
      existingUserIds.includes(userId.toString())
    );

    if (validNewUserIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'None of the provided user IDs correspond to existing users'
      });
    }

    // Add new collaborators to the trip
    trip.collaborators = [...existingCollaboratorIds, ...validNewUserIds];
    await trip.save();

    res.status(200).json({
      success: true,
      message: `Successfully added ${validNewUserIds.length} new collaborator(s)`,
      count: validNewUserIds.length
    });

  } catch (error) {
    console.error('Error adding collaborators:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while adding collaborators'
    });
  }
});

// PUT route: Update collaborators for a trip (only trip owner can do this)
router.put('/trips/:tripId/collaborators', auth, ownerMiddleware('params'), async (req, res) => {
  try {
    const { tripId } = req.params;
    const { collaboratorIds } = req.body;

    // Validate trip ID
    if (!tripId) {
      return res.status(400).json({
        success: false,
        message: 'Trip ID is required'
      });
    }

    // Validate collaborator IDs array
    if (!Array.isArray(collaboratorIds)) {
      return res.status(400).json({
        success: false,
        message: 'Collaborator IDs must be an array'
      });
    }

    // Validate that all collaborator IDs are valid ObjectIds
    const validObjectIds = collaboratorIds.every(id => 
      mongoose.Types.ObjectId.isValid(id)
    );
    
    if (!validObjectIds) {
      return res.status(400).json({
        success: false,
        message: 'All collaborator IDs must be valid Object IDs'
      });
    }

    // Use the trip from middleware (already validated as owner)
    const trip = req.trip;

    // Update collaborators array
    trip.collaborators = collaboratorIds;
    await trip.save();

    // Populate user details for response
    await trip.populate('collaborators', 'name email imageUrl');

    res.status(200).json({
      success: true,
      message: 'Collaborators updated successfully',
      trip: {
        id: trip._id,
        collaborators: trip.collaborators
      }
    });

  } catch (error) {
    console.error('Error updating collaborators:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while updating collaborators'
    });
  }
});

module.exports = router;

