const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');
const {
  normalizeEmail,
  validateUniversityEmail,
  getAccountTypeFromEmail,
} = require('./university-email');

const User = sequelize.models.User || sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  firebaseUid: { type: DataTypes.STRING, allowNull: false, unique: true },
  fullName: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING, allowNull: false, unique: true },
  accountType: {
    type: DataTypes.ENUM('STUDENT', 'STAFF'),
    allowNull: false,
  },
  university: { type: DataTypes.STRING, allowNull: false },
  emailVerified: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  universityVerified: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  status: {
    type: DataTypes.ENUM('PENDING', 'ACTIVE', 'SUSPENDED'),
    allowNull: false,
    defaultValue: 'PENDING',
  },
}, {
  tableName: 'users',
  underscored: true,
});

async function ensureSchema() {
  await sequelize.authenticate();
  await User.sync();
}

async function syncProfile(decodedToken, body = {}, options = {}) {
  await ensureSchema();

  const email = normalizeEmail(decodedToken.email);
  const requestedType =
    typeof body.accountType === 'string'
      ? body.accountType.trim().toUpperCase()
      : getAccountTypeFromEmail(email);

  const validation = validateUniversityEmail(email, requestedType);
  if (!validation.valid) {
    const error = new Error(
      'Adresse universitaire non autorisee. Utilisez edu.uiz.ac.ma ou uiz.ac.ma.',
    );
    error.statusCode = 403;
    throw error;
  }

  if (options.requireVerifiedEmail && decodedToken.email_verified !== true) {
    const error = new Error('Verification de l’adresse universitaire requise.');
    error.statusCode = 403;
    throw error;
  }

  const [user, created] = await User.findOrCreate({
    where: { firebaseUid: decodedToken.uid },
    defaults: {
      firebaseUid: decodedToken.uid,
      fullName: body.fullName?.trim() || decodedToken.name || email.split('@')[0],
      email: validation.email,
      accountType: validation.accountType,
      university: body.university?.trim() || 'Universite Ibn Zohr',
      emailVerified: decodedToken.email_verified === true,
      universityVerified: false,
    },
  });

  if (!created) {
    if (user.accountType !== validation.accountType) {
      const error = new Error('Le type de compte ne correspond pas au domaine email.');
      error.statusCode = 409;
      throw error;
    }
    await user.update({
      fullName: body.fullName?.trim() || user.fullName,
      email: validation.email,
      emailVerified: decodedToken.email_verified === true,
    });
  }

  return user;
}

function getProfile(decodedToken) {
  return User.findOne({ where: { firebaseUid: decodedToken.uid } });
}

module.exports = {
  User,
  syncProfile,
  getProfile,
};
