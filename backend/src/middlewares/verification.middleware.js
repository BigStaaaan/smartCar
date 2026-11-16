function requireVerifiedMember(req, res, next) {
  if (!req.user || req.user.email_verified !== true || req.user.memberVerified !== true) {
    return res.status(403).json({ error: 'Verified university membership required' });
  }
  return next();
}

module.exports = requireVerifiedMember;