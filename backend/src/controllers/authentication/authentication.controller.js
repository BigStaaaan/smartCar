const authenticationService = require('../../services/authentication/authentication.service');

function publicUser(user) {
  if (!user) return null;
  return {
    id: user.id,
    firebaseUid: user.firebaseUid,
    fullName: user.fullName,
    email: user.email,
    accountType: user.accountType,
    universityVerified: user.universityVerified === true,
    role: user.role || 'PASSENGER',
    activeMode: user.activeMode || 'PASSENGER',
    driverProfile: user.driverProfile || null,
    studentCardUrl: user.studentCardUrl || null,
    verificationStatus: user.verificationStatus || 'PENDING',
  };
}

async function register(req, res) {
  const user = await authenticationService.syncProfile(req.user, req.body);
  return res.status(201).json({
    user: publicUser(user),
  });
}

async function google(req, res) {
  const user = await authenticationService.syncProfile(
    req.user,
    req.body,
    { requireVerifiedEmail: true },
  );
  return res.status(200).json({
    user: publicUser(user),
  });
}

async function me(req, res) {
  const user = await authenticationService.getProfile(req.user);
  return res.json({ user: publicUser(user) });
}

async function verificationStatus(req, res) {
  const user = await authenticationService.markEmailVerified(req.user);
  return res.json({
    emailVerified: req.user.email_verified === true,
    universityVerified: user?.universityVerified === true,
    verificationStatus: user?.verificationStatus || 'NOT_SUBMITTED',
    submittedAt: user?.submittedAt || null,
    reviewedAt: user?.reviewedAt || null,
    rejectionReason: user?.rejectionReason || null,
  });
}

async function verifyUniversity(req, res) {
  const user = await authenticationService.verifyUniversity(req.user);
  return res.json({ user: publicUser(user) });
}

async function approveUniversity(req, res) {
  const user = await authenticationService.approveUniversity(
    req.params.firebaseUid,
  );
  return res.json({ user: publicUser(user) });
}

async function activateDriver(req, res) {
  const user = await authenticationService.activateDriver(req.user, req.body);
  return res.json({ user: publicUser(user) });
}

async function switchMode(req, res) {
  const user = await authenticationService.switchMode(req.user, req.body.activeMode);
  return res.json({ user: publicUser(user) });
}

async function logout(req, res) {
  return res.status(204).send();
}

module.exports = {
  register,
  google,
  me,
  verificationStatus,
  verifyUniversity,
  approveUniversity,
  activateDriver,
  switchMode,
  logout,
};
