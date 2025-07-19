const config = require( 'config' );
const jwt = require( 'jsonwebtoken');
const mongoose = require( 'mongoose' );
const Joi = require( 'joi' ).extend(require('joi-phone-number'));
const validator = require('validator');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true,'Name is required'],
        minlength: 1,
        maxlength: 50,
    },
    email: {
        type: String,
        trim: true,
        unique: true,
        required: [true,'Email address is required'],
        validate: [validator.isEmail, 'Please fill a valid email address'],
    },
    password: {
        type: String,
        required: [true,'Password is required'],
        minlength: 8,
        maxlength: 1024//hashed password can be long
    },
    imageUrl: {
        type: String,
        validate: [validator.isURL, 'Invalid image URL'], 
    },
    phone: {
        type: String,
        vadidate: [validator.isMobilePhone,'Invalid Phone Number'],
    },
    emergencyContacts: {
        type: [String],
        validate: {
            validator: (value) =>
                value.every((phone) => validator.isMobilePhone(phone, ))
        },
    },
    resetToken: String,
    resetTokenExpiry: Date
});

userSchema.methods.generateAuthToken = function() {
    const token = jwt.sign({ _id: this.id },config.get('jwtPrivateKey'));
    return token;
}

const User = mongoose.model('User', userSchema);

function validateUser(user) {
    const schema = Joi.object({
        name: Joi.string().min(1).max(50).required(),
        email: Joi.string().required().email(),
        password: Joi.string().min(6).max(25).required(),
        imageUrl: Joi.string().uri(),
        phone: Joi.string().phoneNumber(),
        emergencyContacts: Joi.array().items(Joi.string().phoneNumber())
    });

    return schema.validate(user);
}

module.exports.User = User;
exports.validateUser = validateUser;