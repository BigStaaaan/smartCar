const express = require('express');

const router = express.Router();
router.get('/health', (req, res) => res.json({ status: 'ok', service: 'smartcar-api' }));
router.use('/auth', require('./authentication/authentication.routes'));
router.use('/verification', require('../modules/university-verification/verification.routes'));

router.use('/vehicles', require('./vehicles/vehicles.routes'));

module.exports = router;