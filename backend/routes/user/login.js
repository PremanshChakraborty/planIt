const express = require('express');
const bcrypt = require('bcrypt');
const Joi = require('joi');
const { User } = require('../../models/user');
const winston = require('winston');

const router = express.Router();

router.post('/', async (req, res) => {
    const { error } = validateLogin(req.body);
    if (error) {
        winston.warn(`Validation failed for email: ${req.body.email} - ${error.details[0].message}`);
        return res.status(400).send(error.details[0].message);
    }

    const user = await User.findOne({ email: req.body.email });
    if (!user) {
        winston.warn(`Login attempt with non-existent email: ${req.body.email}`);
        return res.status(400).send('Invalid email or password.');
    }

    const validPassword = await bcrypt.compare(req.body.password, user.password);
    if (!validPassword) {
        winston.warn(`Failed login attempt for email: ${req.body.email}`);
        return res.status(400).send('Invalid email or password.');
    }

    const token = user.generateAuthToken();
    winston.info(`User logged in successfully: ${user.email}`);

    res.header('x-auth-token', token).status(200).send({
        message: 'Login successful',
        user: {
            id: user._id,
            name: user.name,
            email: user.email,
            imageUrl: user.imageUrl,
            phone: user.phone,
            emergencyContacts: user.emergencyContacts,
        },
    });
});

function validateLogin(req) {
    const schema = Joi.object({
        email: Joi.string().email().required(),
        password: Joi.string().min(6).max(25).required(),
    });
    return schema.validate(req);
}

module.exports = router;
