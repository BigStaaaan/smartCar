const express = require('express');
const authenticate = require('../../middlewares/auth.middleware');
const authenticationController = require('../../controllers/authentication/authentication.controller');
const asyncHandler = require('../../utils/async-handler');

const router = express.Router();

router.post('/register', authenticate, asyncHandler(authenticationController.register));
router.post('/google', authenticate, asyncHandler(authenticationController.google));
router.get('/verification-status', authenticate, asyncHandler(authenticationController.verificationStatus));
router.get('/me', authenticate, asyncHandler(authenticationController.me));
router.post('/logout', authenticate, asyncHandler(authenticationController.logout));

module.exports = router;
