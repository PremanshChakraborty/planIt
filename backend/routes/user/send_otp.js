const express = require('express');
const bcrypt = require('bcrypt');
const Joi = require( 'joi' );
const {Otp} = require('../../models/otp');
const sendEmail = require('../../utils/send_email');

const router = express.Router();

router.post('/', async (req,res) => {
    const { error } = validate(req.body);
    if(error) return res.status(400).send(error.details[0].message);

    await Otp.deleteOne({ email : req.body.email });

    const generatedOtp = generateOtp();

    const salt = await bcrypt.genSalt(10);
    const hashedOtp = await bcrypt.hash(generatedOtp,salt);
    const newOtp = new Otp({
        email: req.body.email,
        otp: hashedOtp,
        createdAt: Date.now(),
        expiresAt: new Date(Date.now() + 10 * 60000)
    });
    await newOtp.save();

    await sendEmail(req.body.email,generatedOtp);

    res.status(200).send('sent');
});

function validate(req){
    const schema = Joi.object({
        email: Joi.string().required().email()
    })

    return schema.validate(req);
}

function generateOtp() {
    return (`${Math.floor(100000 + Math.random() * 900000)}`);
}

module.exports = router;