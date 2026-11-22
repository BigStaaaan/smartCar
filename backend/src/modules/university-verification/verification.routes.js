const express = require('express');
const multer = require('multer');
const authenticate = require('../../middlewares/auth.middleware');
const asyncHandler = require('../../utils/async-handler');
const service = require('./verification.service');
const controller = require('./verification.controller');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
  fileFilter(_req, file, callback) {
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) {
      return callback(new Error('Student card must be JPG, PNG or WEBP.'));
    }
    return callback(null, true);
  },
});

const router = express.Router();

router.use((req, _res, next) => {
  req.verificationService = service;
  return next();
});

router.get('/status', authenticate, asyncHandler(controller.getStatus));
router.post(
  '/request',
  authenticate,
  upload.single('studentCard'),
  asyncHandler(controller.submitRequest),
);

router.get(
  '/admin/requests',
  authenticate,
  authenticate.requireAdmin,
  asyncHandler(controller.listRequests),
);
router.get(
  '/admin/requests/:firebaseUid',
  authenticate,
  authenticate.requireAdmin,
  asyncHandler(controller.getRequest),
);
router.post(
  '/admin/requests/:firebaseUid/decision',
  authenticate,
  authenticate.requireAdmin,
  asyncHandler(controller.decideRequest),
);
router.get(
  '/admin/requests/:firebaseUid/card',
  authenticate,
  authenticate.requireAdmin,
  asyncHandler(controller.previewCard),
);

module.exports = router;
