const mongoose = require('mongoose');

const tripSchema = new mongoose.Schema(
  {
    startLocation: {
      placeId: { type: String, required: true, minlength: 1, trim: true },
      placeName: { type: String, required: true, minlength: 3, trim: true },
      day: { type: Number, required: true, min: 1, max: 1 },
      latitude: { type: Number, required: false },
      longitude: { type: Number, required: false },
      attractions: {
        type: [
          {
            placeId: { type: String, required: true, minlength: 1, trim: true },
            name: { type: String, required: true, minlength: 1, trim: true },
            type: { type: String, required: true, trim: true },
            rating: { type: Number, required: true },
            image: { type: String, required: true, trim: true },
          }
        ],
      },
    },
    locations: {
      type: [
        {
          placeId: { type: String, required: true, minlength: 1, trim: true },
          placeName: { type: String, required: true, minlength: 3, trim: true },
          day: { type: Number, required: true, min: 1 },
          latitude: { type: Number, required: false },
          longitude: { type: Number, required: false },
          attractions: {
            type: [
              {
                placeId: { type: String, required: true, minlength: 1, trim: true },
                name: { type: String, required: true, minlength: 1, trim: true },
                type: { type: String, required: true, trim: true },
                rating: { type: Number, required: true },
                image: { type: String, required: true, trim: true },
              }
            ],
            default: [],
          },
        }
      ],
      validate: {
        validator: function (val) {
          return (
            Array.isArray(val) &&
            val.length >= 2 &&
            val.every(
              loc =>
                typeof loc.placeId === 'string' &&
                loc.placeId.length >= 1 &&
                typeof loc.placeName === 'string' &&
                loc.placeName.length >= 3 &&
                typeof loc.day === 'number' &&
                loc.day >= 1 &&
                (loc.latitude === null || loc.latitude === undefined || typeof loc.latitude === 'number') &&
                (loc.longitude === null || loc.longitude === undefined || typeof loc.longitude === 'number') &&
                (loc.attractions === null || Array.isArray(loc.attractions))
            )
          );
        },
        message: 'At least two locations are required, each with a valid placeId, placeName (min 3 chars), day (>=1), and optional latitude/longitude.',
      },
      required: true,
    },
    startDate: {
      type: Date,
      required: true,
    },
    guests: {
      type: Number,
      min: 0,
      max: 10,
      required: true,
    },
    budget: {
      type: String,
      trim: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  { timestamps: true }
);

const Trip = mongoose.model('Trip', tripSchema);

module.exports = Trip;
