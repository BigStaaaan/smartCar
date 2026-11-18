const authenticationService = require('../../services/authentication/authentication.service');

async function register(req, res) {
  const user = await authenticationService.syncProfile(req.user, req.body);
  return res.status(201).json({
    user: {
      id: user.id,
      firebaseUid: user.firebaseUid,
      fullName: user.fullName,
      email: user.email,
      accountType: user.accountType,
      universityVerified: user.universityVerified,
    },
  });
}

async function google(req, res) {
  const user = await authenticationService.syncProfile(
    req.user,
    req.body,
    { requireVerifiedEmail: true },
  );
  return res.status(200).json({
    user: {
      id: user.id,
      firebaseUid: user.firebaseUid,
      fullName: user.fullName,
      email: user.email,
      accountType: user.accountType,
      universityVerified: user.universityVerified,
    },
  });
}

async function me(req, res) {
  const user = await authenticationService.getProfile(req.user);
  return res.json({ user: user || null });
}

async function verificationStatus(req, res) {
  const user = await authenticationService.markEmailVerified(req.user);
  return res.json({
    emailVerified: req.user.email_verified === true,
    universityVerified: user?.universityVerified === true,
  });
}

async function logout(req, res) {
  return res.status(204).send();
}

module.exports = {
  register,
  google,
  me,
  verificationStatus,
  logout,
};
