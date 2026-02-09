const express = require('express');
const router = express.Router();
const Joi = require('joi');
const mongoose = require('mongoose');
const DayPlan = require('../../models/dayPlan');
const Trip = require('../../models/trip');
const collaboratorMiddleware = require('../../middleware/collaborator');

// Validation function for day plan
function validateDayPlan(dayPlan) {
    const planBlockSchema = Joi.object({
        placeId: Joi.string().min(1).required(),
        name: Joi.string().min(1).required(),
        type: Joi.string().valid('attraction', 'hotel').required(),
        image: Joi.string().required(),
        rating: Joi.number().required(),
        latitude: Joi.number().required(),
        longitude: Joi.number().required(),
        addedBy: Joi.object({
            userId: Joi.string().required(),
            userName: Joi.string().required(),
            imageUrl: Joi.string().optional().allow('').allow(null),
        }).optional(),
    });

    const schema = Joi.object({
        id: Joi.string().allow('', null).optional(),
        planTitle: Joi.string().min(1).required(),
        tripId: Joi.string().required(),
        locationId: Joi.string().min(1).required(),
        day: Joi.number().min(1).required(),
        sequence: Joi.array().items(planBlockSchema).default([]),
        createdBy: Joi.object({
            userId: Joi.string().optional().allow(''),
            userName: Joi.string().optional().allow(''),
            imageUrl: Joi.string().optional().allow('').allow(null),
        }).optional(),
        updatedBy: Joi.object({
            userId: Joi.string().optional().allow(''),
            userName: Joi.string().optional().allow(''),
            imageUrl: Joi.string().optional().allow('').allow(null),
        }).optional().allow(null),
        isStarred: Joi.boolean().required().default(false),
    });

    return schema.validate(dayPlan);
}

// POST route: Create or update a day plan
router.post('/', collaboratorMiddleware('body'), async (req, res) => {
    try {
        // Validate the request body
        const { error } = validateDayPlan(req.body);
        if (error) {
            return res.status(400).json({
                success: false,
                message: error.details[0].message,
            });
        }

        const { id, planTitle, tripId, locationId, day, sequence, isStarred } = req.body;

        // Check if this is a create or update operation
        const isUpdate = id && id.trim() !== '';

        if (isUpdate) {
            // UPDATE OPERATION
            // Validate that id is a valid ObjectId
            if (!mongoose.Types.ObjectId.isValid(id)) {
                return res.status(400).json({
                    success: false,
                    message: 'Invalid day plan ID format',
                });
            }

            // Check if day plan exists
            const existingDayPlan = await DayPlan.findById(id)
                .populate('createdBy', 'name email imageUrl')
                .populate('updatedBy', 'name email imageUrl')
                .populate('sequence.addedBy', 'name email imageUrl');

            if (!existingDayPlan) {
                return res.status(404).json({
                    success: false,
                    message: 'Day plan not found',
                });
            }

            // Check if the current user is the creator/owner of the day plan
            if (existingDayPlan.createdBy._id.toString() !== req.user._id.toString()) {
                return res.status(403).json({
                    success: false,
                    message: 'You are not authorized to update this day plan. Only the creator can update it.',
                });
            }

            // Process sequence to ensure addedBy references are ObjectIds
            const processedSequence = sequence.map(block => {
                if (block.addedBy && block.addedBy.userId) {
                    return {
                        ...block,
                        addedBy: block.addedBy.userId,
                    };
                }
                return {
                    ...block,
                    addedBy: block.addedBy || req.user._id,
                };
            });

            // Update the day plan
            existingDayPlan.planTitle = planTitle;
            existingDayPlan.tripId = tripId;
            existingDayPlan.locationId = locationId;
            existingDayPlan.day = day;
            existingDayPlan.sequence = processedSequence;
            existingDayPlan.isStarred = isStarred;
            existingDayPlan.updatedBy = req.user._id;

            await existingDayPlan.save();

            // Populate and return the updated day plan
            const updatedDayPlan = await DayPlan.findById(existingDayPlan._id)
                .populate('createdBy', 'name email imageUrl')
                .populate('updatedBy', 'name email imageUrl')
                .populate('sequence.addedBy', 'name email imageUrl');

            return res.status(200).json({
                success: true,
                message: 'Day plan updated successfully',
                dayPlan: updatedDayPlan,
            });
        } else {
            // CREATE OPERATION
            // Process sequence to ensure addedBy references are ObjectIds
            const processedSequence = sequence.map(block => {
                if (block.addedBy && block.addedBy.userId) {
                    return {
                        ...block,
                        addedBy: block.addedBy.userId,
                    };
                }
                return {
                    ...block,
                    addedBy: block.addedBy || req.user._id,
                };
            });

            // Create new day plan
            let newDayPlan = new DayPlan({
                planTitle,
                tripId,
                locationId,
                day,
                sequence: processedSequence,
                isStarred,
                createdBy: req.user._id,
            });

            newDayPlan = await newDayPlan.save();

            // Populate and return the new day plan
            const populatedDayPlan = await DayPlan.findById(newDayPlan._id)
                .populate('createdBy', 'name email imageUrl')
                .populate('updatedBy', 'name email imageUrl')
                .populate('sequence.addedBy', 'name email imageUrl');

            return res.status(201).json({
                success: true,
                message: 'Day plan created successfully',
                dayPlan: populatedDayPlan,
            });
        }
    } catch (error) {
        console.error('Error creating/updating day plan:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error while processing day plan',
            error: error.message,
        });
    }
});

// GET route: Retrieve all day plans for a specific trip
router.get('/trip/:tripId', collaboratorMiddleware('params'), async (req, res) => {
    try {
        const { tripId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(tripId)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid trip ID format',
            });
        }

        const dayPlans = await DayPlan.find({ tripId })
            .populate('createdBy', 'name email imageUrl')
            .populate('updatedBy', 'name email imageUrl')
            .populate('sequence.addedBy', 'name email imageUrl')
            .sort({ day: 1 });

        return res.status(200).json({
            success: true,
            dayPlans,
            count: dayPlans.length,
        });
    } catch (error) {
        console.error('Error fetching day plans:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error while fetching day plans',
        });
    }
});

// GET route: Retrieve a specific day plan by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid day plan ID format',
            });
        }

        const dayPlan = await DayPlan.findById(id)
            .populate('createdBy', 'name email imageUrl')
            .populate('updatedBy', 'name email imageUrl')
            .populate('sequence.addedBy', 'name email imageUrl');

        if (!dayPlan) {
            return res.status(404).json({
                success: false,
                message: 'Day plan not found',
            });
        }

        return res.status(200).json({
            success: true,
            dayPlan,
        });
    } catch (error) {
        console.error('Error fetching day plan:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error while fetching day plan',
        });
    }
});

// PARTIAL UPDATE route: Toggle isStarred status
router.patch('/:id/toggle-star', async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid day plan ID format',
            });
        }

        const dayPlan = await DayPlan.findById(id);

        if (!dayPlan) {
            return res.status(404).json({
                success: false,
                message: 'Day plan not found',
            });
        }

        const trip = await Trip.findById(dayPlan.tripId);
        if (!trip) {
            return res.status(404).json({
                success: false,
                message: 'Associated trip not found',
            });
        }

        // Restrict star toggle to Trip Owner ONLY
        if (trip.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Only the trip owner can star/unstar this plan.',
            });
        }

        dayPlan.isStarred = !dayPlan.isStarred;
        await dayPlan.save();

        return res.status(200).json({
            success: true,
            isStarred: dayPlan.isStarred,
            message: 'Day plan star status toggled successfully',
        });
    } catch (error) {
        console.error('Error toggling star status:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error while toggling star status',
        });
    }
});

// DELETE route: Delete a day plan (only creator or trip owner can delete)
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid day plan ID format',
            });
        }

        const dayPlan = await DayPlan.findById(id);

        if (!dayPlan) {
            return res.status(404).json({
                success: false,
                message: 'Day plan not found',
            });
        }

        const trip = await Trip.findById(dayPlan.tripId);

        // Check if the current user is the creator OR trip owner
        const isCreator = dayPlan.createdBy.toString() === req.user._id.toString();
        const isTripOwner = trip && trip.user.toString() === req.user._id.toString();

        if (!isCreator && !isTripOwner) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to delete this day plan.',
            });
        }

        await DayPlan.findByIdAndDelete(id);

        return res.status(200).json({
            success: true,
            message: 'Day plan deleted successfully',
        });
    } catch (error) {
        console.error('Error deleting day plan:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error while deleting day plan',
        });
    }
});

module.exports = router;
