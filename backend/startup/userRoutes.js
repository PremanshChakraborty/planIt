const express = require('express');
const auth = require('../middleware/auth');
const root = require('../routes/root/root')
const signup = require('../routes/user/signup');
const sendOtp = require('../routes/user/send_otp');
const login = require('../routes/user/login');
const verifyOtp = require('../routes/user/verify_otp');
const editProfile = require('../routes/user/edit_profile');
const tripRoutes = require('../routes/trip/triproute');
const collabRoutes = require('../routes/collaborations/collabRoutes');
const getUser = require('../routes/user/get_user');
const dayPlanRoutes = require('../routes/dayplan/dayPlanRoute');


module.exports = function (app) {
    app.use('/', root);
    app.use('/api/user/signUp', signup);
    app.use('/api/user/send_otp', sendOtp);
    app.use('/api/user/login', login);
    app.use('/api/user/verify_otp', verifyOtp);
    app.use('/api/user/profile', editProfile);
    app.use('/api/trips', auth, tripRoutes);
    app.use('/api/collaborations', auth, collabRoutes);
    app.use('/api/users', auth, getUser);
    app.use('/api/dayplans', auth, dayPlanRoutes);
}