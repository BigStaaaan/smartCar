const authenticationService = require('../services/authentication/authentication.service');

async function requireVerifiedMember(req, res, next) {
  if (!req.user || req.user.email_verified !== true) {
    return res.status(403).json({ error: 'Verified university membership required' });
  }
  try {
    const user = await authenticationService.getProfile(req.user);
    if (!user || user.universityVerified !== true) {
      return res.status(403).json({ error: 'Verified university membership required' });
    }
    req.smartCarUser = user;
    return next();
  } catch (error) {
    return next(error);
  }
}

async function requireDriverMode(req, res, next) {
  if (!req.user || req.user.email_verified !== true) {
    return res.status(403).json({ error: 'Verified university membership required' });
  }
  try {
    const user = await authenticationService.getProfile(req.user);
    if (!user || user.universityVerified !== true) {
      return res.status(403).json({ error: 'Verified university membership required' });
    }
    if (user.role !== 'DRIVER' || user.activeMode !== 'DRIVER' || !user.driverProfile) {
      return res.status(403).json({ error: 'Driver Mode is required for this operation' });
    }
    req.smartCarUser = user;
    return next();
  } catch (error) {
    return next(error);
  }
}

module.exports = requireVerifiedMember;
module.exports.requireVerifiedMember = requireVerifiedMember;
module.exports.requireDriverMode = requireDriverMode;