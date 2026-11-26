const { User } = require('../services/authentication/authentication.service');

async function findOwnerId(firebaseUid, transaction) {
  const user = await User.findOne({
    where: { firebaseUid },
    attributes: ['id', 'firebaseUid'],
    transaction,
  });
  return user?.firebaseUid === firebaseUid ? user.id : null;
}

async function requireOwnerId(firebaseUid, transaction) {
  const ownerId = await findOwnerId(firebaseUid, transaction);
  if (!ownerId) {
    const message = 'SmartCar user profile not found';
    throw Object.assign(new Error(message), { statusCode: 404, publicMessage: message });
  }
  return ownerId;
}

module.exports = { findOwnerId, requireOwnerId };
