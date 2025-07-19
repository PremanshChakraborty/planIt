const mongoose = require('mongoose');
const validator = require('validator');

const otpSchema = new mongoose.Schema({
    email: {
            type: String,
            trim: true,
            unique: true,
            required: [true,'Email address is required'],
            validate: [validator.isEmail, 'Please fill a valid email address'],
        },
    otp: String,
    createdAt: Date,
    expiresAt: Date,
});

const Otp = new mongoose.model("Otp",otpSchema);

module.exports.Otp = Otp;