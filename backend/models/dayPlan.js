const mongoose = require('mongoose');

const planBlockSchema = new mongoose.Schema({
  placeId: { type: String, required: true, minlength: 1, trim: true },
  name: { type: String, required: true, minlength: 1, trim: true },
  type: { type: String, required: true, enum: ['attraction', 'hotel'], trim: true },
  image: { type: String, required: true, trim: true },
  rating: { type: Number, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
}, { _id: false });

const dayPlanSchema = new mongoose.Schema(
  {
    planTitle: { type: String, required: true, minlength: 1, trim: true },
    tripId: { type: mongoose.Schema.Types.ObjectId, ref: 'Trip', required: true },
    locationId: { type: String, required: true, minlength: 1, trim: true },
    day: { type: Number, required: true, min: 1 },
    sequence: {
      type: [planBlockSchema],
      default: [],
    },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false },
    isStarred: { type: Boolean, required: true, default: false },
  },
  { timestamps: true }
);

const DayPlan = mongoose.model('DayPlan', dayPlanSchema);

module.exports = DayPlan;
