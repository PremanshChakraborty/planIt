const express = require('express');
const router = express.Router();
const Joi = require('joi');
const Trip = require('../../models/trip');

// Validation function for trip details
function validateTrip(trip) {
  const attractionSchema = Joi.object({
    placeId: Joi.string().min(1).required(),
    name: Joi.string().min(1).required(),
    type: Joi.string().required(),
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

// GET route: Retrieve all trips for the authenticated user
router.get('/', async (req, res) => {
  const trips = await Trip.find({ user: req.user._id }).populate('user', 'name email');
  res.status(200).send(trips);
});

// GET by ID route: Retrieve a specific trip by its ID
router.get('/:id', async (req, res) => {
  const trip = await Trip.findById(req.params.id).populate('user', 'name email');
  if (!trip) return res.status(404).send('Trip not found');
  res.status(200).send(trip);
});

// PUT route: Edit an existing trip (all editable fields specified fresh in body)
router.put('/:id', async (req, res) => {
  const { error } = validateTrip(req.body);
  if (error) return res.status(400).send(error.details[0].message);

  // Only allow editing of startLocation, locations, startDate, guests
  const updateFields = {
    startLocation: req.body.startLocation,
    locations: req.body.locations,
    startDate: req.body.startDate,
    guests: req.body.guests,
  };

  const trip = await Trip.findOneAndUpdate(
    { _id: req.params.id, user: req.user._id },
    updateFields,
    { new: true }
  );

  if (!trip) return res.status(404).send('Trip not found or not authorized');
  res.status(200).send({
    success: true, 
    message: 'Trip updated successfully',
    trip: trip
  });
});

// DELETE route: Delete an existing trip
router.delete('/:id', async (req, res) => {
  const trip = await Trip.findOneAndDelete({ _id: req.params.id, user: req.user._id });
  if (!trip) return res.status(404).send('Trip not found or not authorized');
  res.status(200).send({ message: 'Trip deleted successfully' });
});

// PATCH route: Edit saved attraction in a trip location
router.patch('/attraction', async (req, res) => {
  const { tripId, locationIndex, attraction } = req.body;
  if (!tripId || typeof locationIndex !== 'number' || !attraction || !attraction.placeId) {
    return res.status(400).send({ success: false, msg: 'tripId, locationIndex, and valid attraction object required' });
  }

  // Only allow editing for authenticated user
  const trip = await Trip.findOne({ _id: tripId, user: req.user._id });
  if (!trip) return res.status(404).send({ success: false, msg: 'Trip not found or not authorized' });

  // Validate location index (skip startLocation, so index 0 is first in locations array)
  if (!Array.isArray(trip.locations) || locationIndex < 0 || locationIndex >= trip.locations.length) {
    return res.status(400).send({ success: false, msg: 'Invalid location index' });
  }

  const loc = trip.locations[locationIndex];
  if (!loc.attractions) loc.attractions = [];

  // Check if attraction already exists (by placeId)
  const existingIdx = loc.attractions.findIndex(a => a.placeId === attraction.placeId);
  if (existingIdx === -1) {
    // Add to start
    loc.attractions.unshift(attraction);
    await trip.save();
    return res.send({ success: true, msg: 'Attraction added' });
  } else {
    // Remove it
    loc.attractions.splice(existingIdx, 1);
    await trip.save();
    return res.send({ success: true, msg: 'Attraction removed' });
  }
});

module.exports = router;
