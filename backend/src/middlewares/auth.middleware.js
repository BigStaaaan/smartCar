const firebase = require('../config/firebase');

async function authenticate(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication token required' });
  }

  try {
    req.user = await firebase.auth().verifyIdToken(header.slice(7));
    return next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid authentication token' });
  }
}

module.exports = authenticate;
module.exports.requireAdmin = function requireAdmin(req, res, next) {
  const role = String(req.user?.role || '').toUpperCase();
  const isAdmin =
    req.user?.admin === true ||
    role === 'ADMIN' ||
    role === 'SUPPORT' ||
    req.user?.claims?.admin === true;
  if (!isAdmin) {
    return res.status(403).json({ error: 'Administrator or Support access required' });
  }
  return next();
};