const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const Joi = require( 'joi' );
const config = require('config');
const { User } = require('../../models/user');

const router = express.Router();

router.post('/',async (req, res) => {
    const { error } = validate(req.body);
    if(error) return res.status(400).send(error.details[0].message);

    const decoded = jwt.verify(req.body.token, config.get('jwtPrivateKey'));
    const user = await User.findOne({ email: decoded.email });

    if (!user || user.resetToken !== req.body.token || Date.now() > user.resetTokenExpiry) {
        return res.status(400).send('Invalid or expired token' );
    }

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(req.body.password,salt);
    user.resetToken = null;
    user.resetTokenExpiry = null;
    await user.save();

    res.status(200).send('Password reset successfully');
});

function validate(req){
    const schema = Joi.object({
        token: Joi.string().required(),
        password: Joi.string().min(6).max(25).required()
    });

    return schema.validate(req);
}

module.exports = router;