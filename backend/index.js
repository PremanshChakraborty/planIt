require('dotenv').config();

const  winston = require('winston');
const express = require('express');
const mongoose = require('mongoose');
const config = require('config');
const error = require('./middleware/error');

const app = express();


require('./startup/logger')();
require('./startup/config')();

app.use(express.json());
require('./startup/userRoutes')(app);
require('./startup/hotelRoutes')(app);
app.use(error);

mongoose.connect(config.get('dbKey'))
    .then( () => winston.info('Connected to Database...'));

const port = process.env.PORT || 3000;
const server = app.listen(port,'0.0.0.0', () => winston.info(`Listening on port ${port}...`));
module.exports = server;