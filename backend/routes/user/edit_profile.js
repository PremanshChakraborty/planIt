const express = require('express');
const bcrypt = require('bcrypt');
const Joi = require('joi').extend(require('joi-phone-number'));
const { User, validateUser } = require('../../models/user');
const auth = require('../../middleware/auth');
const winston = require('winston');

const router = express.Router();

router.put('/', auth, async (req, res) => {
    // Validate request body
    const { error } = validateProfileUpdate(req.body);
    if (error) {
        winston.warn(`Profile update validation failed for user ID: ${req.user._id} - ${error.details[0].message}`);
        return res.status(400).send(error.details[0].message);
    }

    try {
        // Find user by ID from token
        const user = await User.findById(req.user._id);
        if (!user) {
            winston.warn(`Profile update attempted for non-existent user ID: ${req.user._id}`);
            return res.status(404).send('User not found.');
        }

        // Update user fields if provided
        if (req.body.name) user.name = req.body.name;
        if (req.body.email) user.email = req.body.email;
        if (req.body.phone) user.phone = req.body.phone;
        if (req.body.emergencyContacts) user.emergencyContacts = req.body.emergencyContacts;
        
        // Handle password update separately with hashing
        if (req.body.password) {
            const salt = await bcrypt.genSalt(10);
            user.password = await bcrypt.hash(req.body.password, salt);
        }

        // Save the updated user
        await user.save();
        
        winston.info(`User profile updated successfully: ${user.email}`);
        
        // Return updated user info (excluding password)
        res.status(200).send({
            message: 'Profile updated successfully',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                phone: user.phone,
                emergencyContacts: user.emergencyContacts,
            }
        });
    } catch (ex) {
        winston.error(`Error updating profile: ${ex.message}`);
        res.status(500).send('An error occurred while updating profile.');
    }
});

function validateProfileUpdate(req) {
    // Modified version of validateUser that makes all fields optional
    const schema = Joi.object({
        id: Joi.string().optional(),
        name: Joi.string().min(1).max(50),
        email: Joi.string().email(),
        imageUrl: Joi.string().uri().allow('', null).optional(),
        phone: Joi.string().phoneNumber().allow('', null),
        emergencyContacts: Joi.array().items(Joi.string().phoneNumber())
    });

    return schema.validate(req);
}

module.exports = router; 