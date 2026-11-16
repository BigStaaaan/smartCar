const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const environment = require('./config/environment');
const routes = require('./routes');
const errorMiddleware = require('./middlewares/error.middleware');

const app = express();
app.use(helmet());
app.use(cors({ origin: environment.clientOrigin }));
app.use(express.json({ limit: '2mb' }));
app.use('/api/v1', routes);
app.use(errorMiddleware);

module.exports = app;