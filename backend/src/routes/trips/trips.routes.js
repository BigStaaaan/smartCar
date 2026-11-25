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
router.patch('/:id', validate(schemas.update), asyncHandler(controller.update));
router.patch('/:id/cancel', validate(schemas.emptyAction), asyncHandler(controller.cancel));
router.patch('/:id/start', validate(schemas.emptyAction), asyncHandler(controller.start));
router.patch('/:id/complete', validate(schemas.emptyAction), asyncHandler(controller.complete));

module.exports = router;
