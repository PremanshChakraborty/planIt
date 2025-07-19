const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const Joi = require( 'joi' );
const {Otp} = require('../../models/otp');
const config = require('config');
const { User } = require('../../models/user');


const router = express.Router();

router.post('/',async (req, res) => {
    const { error } = validate(req.body);
    if(error) return res.status(400).send(error.details[0].message);

    const matchedOtp = await Otp.findOne({
        email: req.body.email,
    })
    if(!matchedOtp) return res.status(400).send('No OTP record found');

    const {expiresAt} = matchedOtp;
    if(expiresAt<Date.now()) {
        await Otp.deleteOne({ email : req.body.email });
        return res.status(400).send('OTP has expired. Request a new one');
    }

    const hashedOtp = matchedOtp.otp;
    const validOtp = await bcrypt.compare(req.body.otp,hashedOtp);
    if(validOtp) {
        const token = jwt.sign(
            { email : req.body.email },
            config.get('jwtPrivateKey')
        );

        const user = await User.findOne({ email : req.body.email }); 
        user.resetToken = token;
        user.resetTokenExpiry = Date.now() + 10 * 60 * 1000;
        await user.save(); 

        res.header('x-pwdReset-token', token).status(200).json({valid:validOtp});
    }
    else res.status(200).json({valid:validOtp});
});

function validate(req){
    const schema = Joi.object({
        email: Joi.string().required().email(),
        otp: Joi.string().required().length(6)
    });

    return schema.validate(req);
}

module.exports = router;