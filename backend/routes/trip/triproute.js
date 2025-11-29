const express = require('express');
const router = express.Router();
const Joi = require('joi');
const Trip = require('../../models/trip');
const ownerMiddleware = require('../../middleware/owner');
const collaboratorMiddleware = require('../../middleware/collaborator');

// Validation function for trip details
function validateTrip(trip) {
  const attractionSchema = Joi.object({
    placeId: Joi.string().min(1).required(),
    name: Joi.string().min(1).required(),
    type: Joi.string().required(),
    rating: Joi.number().required(),
    image: Joi.string().required(),
  });

  const hotelSchema = Joi.object({
    placeId: Joi.string().min(1).required(),
    name: Joi.string().min(1).required(),
    price: Joi.string().required(),
    rating: Joi.number().required(),
    image: Joi.string().required(),
  });

  const schema = Joi.object({
    startLocation: Joi.object({
      placeId: Joi.string().min(1).required(),
      placeName: Joi.string().min(3).required(),
      day: Joi.number().valid(1).required(),
      latitude: Joi.number().allow(null),
      longitude: Joi.number().allow(null),
      attractions: Joi.array().items(attractionSchema).allow(null),
    }).required(),
    locations: Joi.array()
      .items(
        Joi.object({
          placeId: Joi.string().min(1).required(),
          placeName: Joi.string().min(3).required(),
          day: Joi.number().min(1).required(),
          latitude: Joi.number().allow(null),
          longitude: Joi.number().allow(null),
          attractions: Joi.array().items(attractionSchema).allow(null).default([]),
          hotels: Joi.array().items(hotelSchema).allow(null).default([]),
        })
      )
      .min(2)
      .required(),
    startDate: Joi.date().required(),
    guests: Joi.number().min(0).max(10).required(),
    budget: Joi.string().allow('', null),
  });
  return schema.validate(trip);
}

// Validation function for single location
function validateLocation(location) {
  const attractionSchema = Joi.object({
    placeId: Joi.string().min(1).required(),
    name: Joi.string().min(1).required(),
    type: Joi.string().required(),
    rating: Joi.number().required(),
    image: Joi.string().required(),
  });

  const hotelSchema = Joi.object({
    placeId: Joi.string().min(1).required(),
    name: Joi.string().min(1).required(),
    price: Joi.string().required(),
    rating: Joi.number().required(),
    image: Joi.string().required(),
  });

  const schema = Joi.object({
    placeId: Joi.string().min(1).required(),
    placeName: Joi.string().min(3).required(),
    day: Joi.number().min(1).required(),
    latitude: Joi.number().allow(null),
    longitude: Joi.number().allow(null),
    attractions: Joi.array().items(attractionSchema).default([]).allow(null),
    hotels: Joi.array().items(hotelSchema).default([]).allow(null),
  });
  return schema.validate(location);
}

// POST route: Create a new trip
router.post('/', async (req, res) => {
  const { error } = validateTrip(req.body);
  if (error) return res.status(400).send(error.details[0].message);

  let trip = new Trip({
    startLocation: req.body.startLocation,
    locations: req.body.locations,
    startDate: req.body.startDate,
    guests: req.body.guests,
    budget: req.body.budget,
    user: req.user._id,
  });

  trip = await trip.save();
  res.status(201).send(trip);
});

// GET route: Retrieve all trips where user is owner or collaborator
router.get('/', async (req, res) => {
  try {
    // Find trips where user is the owner
    const ownedTrips = await Trip.find({ user: req.user._id })
      .populate('user', 'name email')
      .populate('collaborators', 'name email imageUrl')
      .populate('startLocation.attractions.addedBy', 'name email')
      .populate('locations.addedBy', 'name email')
      .populate('locations.attractions.addedBy', 'name email')
      .populate('locations.hotels.addedBy', 'name email');

    // Find trips where user is a collaborator
    const collaboratedTrips = await Trip.find({
      collaborators: req.user._id
    })
      .populate('user', 'name email imageUrl')
      .populate('collaborators', 'name email imageUrl')
      .populate('startLocation.attractions.addedBy', 'name email')
      .populate('locations.addedBy', 'name email')
      .populate('locations.attractions.addedBy', 'name email')
      .populate('locations.hotels.addedBy', 'name email');

    // Add owner boolean to each trip
    const ownedTripsWithFlag = ownedTrips.map(trip => ({
      ...trip.toObject(),
      isOwner: true
    }));

    const collaboratedTripsWithFlag = collaboratedTrips.map(trip => ({
      ...trip.toObject(),
      isOwner: false
    }));

    // Combine and sort by creation date (newest first)
    const allTrips = [...ownedTripsWithFlag, ...collaboratedTripsWithFlag]
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.status(200).json({
      success: true,
      trips: allTrips,
      count: allTrips.length,
      ownedCount: ownedTripsWithFlag.length,
      collaboratedCount: collaboratedTripsWithFlag.length
    });

  } catch (error) {
    console.error('Error fetching trips:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while fetching trips'
    });
  }
});

// GET by ID route: Retrieve a specific trip by its ID
router.get('/:id', async (req, res) => {
  const trip = await Trip.findById(req.params.id)
    .populate('user', 'name email')
    .populate('collaborators', 'name email imageUrl')
    .populate('startLocation.attractions.addedBy', 'name email')
    .populate('locations.addedBy', 'name email')
    .populate('locations.attractions.addedBy', 'name email')
    .populate('locations.hotels.addedBy', 'name email');
  if (!trip) return res.status(404).send('Trip not found');
  res.status(200).send(trip);
});

// PUT route: Edit an existing trip (only trip owner can edit)
router.put('/:id', ownerMiddleware('params'), async (req, res) => {
  const { error } = validateTrip(req.body);
  if (error) return res.status(400).send(error.details[0].message);

  // Only allow editing of startLocation, locations, startDate, guests
  const updateFields = {
    startLocation: req.body.startLocation,
    locations: req.body.locations,
    startDate: req.body.startDate,
    guests: req.body.guests,
  };

  // Use the trip from middleware (already validated as owner)
  const trip = req.trip;

  // Update the trip fields
  Object.assign(trip, updateFields);
  await trip.save();

  res.status(200).send({
    success: true,
    message: 'Trip updated successfully',
    trip: trip
  });
});

// POST route: Add a single location to a trip (owners and collaborators can do this)
router.post('/:id/locations', collaboratorMiddleware('params'), async (req, res) => {
  try {
    const { error } = validateLocation(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.details[0].message
      });
    }

    // Use the trip from middleware (already validated access)
    const trip = req.trip;

    // Create new location with addedBy field
    const newLocation = {
      ...req.body,
      addedBy: req.user._id
    };

    // Add location to the end of locations array
    trip.locations.push(newLocation);
    await trip.save();

    res.status(201).json({
      success: true,
      message: 'Location added successfully',
      location: newLocation,
      trip: trip
    });

  } catch (error) {
    console.error('Error adding location:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while adding location'
    });
  }
});

// DELETE route: Delete an existing trip
router.delete('/:id', async (req, res) => {
  const trip = await Trip.findOneAndDelete({ _id: req.params.id, user: req.user._id });
  if (!trip) return res.status(404).send('Trip not found or not authorized');
  res.status(200).send({ message: 'Trip deleted successfully' });
});

// PATCH route: Edit saved attraction in a trip location
router.patch('/attraction', collaboratorMiddleware('body'), async (req, res) => {
  try {
    const { tripId, locationIndex, attraction } = req.body;
    if (!tripId || typeof locationIndex !== 'number' || !attraction || !attraction.placeId) {
      return res.status(400).json({
        success: false,
        message: 'tripId, locationIndex, and valid attraction object required'
      });
    }

    // Use the trip from middleware (already validated access)
    const trip = req.trip;

    // Validate location index (skip startLocation, so index 0 is first in locations array)
    if (!Array.isArray(trip.locations) || locationIndex < 0 || locationIndex >= trip.locations.length) {
      return res.status(400).json({
        success: false,
        message: 'Invalid location index'
      });
    }

    const loc = trip.locations[locationIndex];
    if (!loc.attractions) loc.attractions = [];

    // Check if attraction already exists (by placeId)
    const existingIdx = loc.attractions.findIndex(a => a.placeId === attraction.placeId);
    if (existingIdx === -1) {
      // Add to start with addedBy field
      const attractionWithAddedBy = {
        ...attraction,
        addedBy: req.user._id
      };
      loc.attractions.unshift(attractionWithAddedBy);
      await trip.save();
      return res.json({
        success: true,
        message: 'Attraction added',
        attraction: attractionWithAddedBy
      });
    } else {
      // Remove it
      loc.attractions.splice(existingIdx, 1);
      await trip.save();
      return res.json({
        success: true,
        message: 'Attraction removed'
      });
    }
  } catch (error) {
    console.error('Error managing attraction:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while managing attraction'
    });
  }
});

// PATCH route: Toggle saved hotel in a trip location
router.patch('/hotel', collaboratorMiddleware('body'), async (req, res) => {
  try {
    const { tripId, locationIndex, hotel } = req.body;
    if (!tripId || typeof locationIndex !== 'number' || !hotel || !hotel.placeId) {
      return res.status(400).json({
        success: false,
        message: 'tripId, locationIndex, and valid hotel object required'
      });
    }

    // Use the trip from middleware (already validated access)
    const trip = req.trip;

    // Validate location index (skip startLocation, so index 0 is first in locations array)
    if (!Array.isArray(trip.locations) || locationIndex < 0 || locationIndex >= trip.locations.length) {
      return res.status(400).json({
        success: false,
        message: 'Invalid location index'
      });
    }

    const loc = trip.locations[locationIndex];
    if (!loc.hotels) loc.hotels = [];

    const existingIdx = loc.hotels.findIndex(h => h.placeId === hotel.placeId);
    if (existingIdx === -1) {
      // Add to start with addedBy field
      const hotelWithAddedBy = {
        ...hotel,
        addedBy: req.user._id
      };
      loc.hotels.unshift(hotelWithAddedBy);
      await trip.save();
      return res.json({
        success: true,
        message: 'Hotel added',
        hotel: hotelWithAddedBy
      });
    } else {
      // Remove it
      loc.hotels.splice(existingIdx, 1);
      await trip.save();
      return res.json({
        success: true,
        message: 'Hotel removed'
      });
    }
  } catch (error) {
    console.error('Error managing hotel:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error while managing hotel'
    });
  }
});

module.exports = router;
