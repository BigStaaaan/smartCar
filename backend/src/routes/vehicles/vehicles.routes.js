const express = require('express');
const multer = require('multer');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const asyncHandler = require('../../utils/async-handler');
const controller = require('../../controllers/vehicles/vehicles.controller');
const schemas = require('../../validators/vehicles/vehicles.validator');

const uploadImages = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: schemas.maxImageBytes + 1, files: 2, fields: 8 },
  fileFilter(_req, file, callback) {
    if (['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) {
      return callback(null, true);
    }
    return callback(new Error('Vehicle documents must be JPG, PNG or WEBP'));
  },
}).fields([
  { name: 'photo', maxCount: 1 },
  { name: 'registrationPhoto', maxCount: 1 },
]);

function matchesImageType({ buffer, mimetype }) {
  switch (mimetype) {
    case 'image/jpeg':
      return buffer.subarray(0, 3).toString('hex') === 'ffd8ff';
    case 'image/png':
      return buffer.subarray(0, 8).toString('hex') === '89504e470d0a1a0a';
    case 'image/webp':
      return buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
        buffer.subarray(8, 12).toString('ascii') === 'WEBP';
    default:
      return false;
  }
}

function readImages(req, res, next) {
  uploadImages(req, res, (error) => {
    if (error) {
      const tooLarge = error.code === 'LIMIT_FILE_SIZE';
      return res.status(tooLarge ? 413 : 400).json({
        error: tooLarge ? 'Vehicle images must be at most 2 MiB each' : 'Invalid vehicle image upload',
      });
    }
    for (const [field, [file]] of Object.entries(req.files ?? {})) {
      if (Object.hasOwn(req.body, field)) {
        return res.status(400).json({ error: 'Send each image as one file' });
      }
      if (file.buffer.length > schemas.maxImageBytes) {
        return res.status(413).json({ error: 'Vehicle images must be at most 2 MiB each' });
      }
      if (!matchesImageType(file)) {
        return res.status(400).json({ error: 'Invalid vehicle image content' });
      }
      req.body[field] = file.buffer;
    }
    return next();
  });
}

const router = express.Router();

router.use((_req, res, next) => {
  res.set('Cache-Control', 'no-store');
  next();
});
router.use(authenticate);
router.get('/', asyncHandler(controller.list));
router.get('/:id', asyncHandler(controller.get));
router.post('/', readImages, validate(schemas.create), asyncHandler(controller.create));
router.patch('/:id', readImages, validate(schemas.update), asyncHandler(controller.update));
router.delete('/:id', asyncHandler(controller.remove));

module.exports = router;
