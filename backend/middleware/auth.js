const jwt = require('jsonwebtoken');
const config = require('config');
const { User } = require('../models/user');

module.exports = async function auth(req, res, next) {
    const token = req.header('x-auth-token');
    if (!token) return res.status(401).send('Access denied No token provided');

    try {
        const decoded = jwt.verify(token, config.get('jwtPrivateKey'));

        // Fetch full user object from database
        const user = await User.findById(decoded._id).select('name email imageUrl');
        if (!user) return res.status(404).send('User not found');

        req.user = user;
        next();
    }
    catch (ex) {
        res.status(400).send('Invalid token');
    }
};