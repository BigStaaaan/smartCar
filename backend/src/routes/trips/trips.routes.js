const express = require('express');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const schemas = require('../../validators/trips/trips.validator');
const asyncHandler = require('../../utils/async-handler');
const controller = require('../../controllers/trips/trips.controller');

const router = express.Router();

router.use((_req, res, next) => {
  res.set('Cache-Control', 'no-store');
  next();
});
router.use(authenticate);
router.get('/', asyncHandler(controller.list));
router.get('/:id', asyncHandler(controller.get));
router.post('/', validate(schemas.create), asyncHandler(controller.create));

module.exports = router;
