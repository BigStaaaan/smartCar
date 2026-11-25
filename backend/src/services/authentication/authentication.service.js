const fs = require('fs');
const path = require('path');
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
  studentCardUrl: { type: DataTypes.STRING, allowNull: true },
  verificationStatus: {
    type: DataTypes.ENUM(
      'NOT_SUBMITTED',
      'PENDING',
      'APPROVED',
      'REJECTED',
      'REQUIRES_RESUBMISSION',
    ),
    allowNull: false,
    defaultValue: 'NOT_SUBMITTED',
  },
  studentId: { type: DataTypes.STRING, allowNull: true },
  faculty: { type: DataTypes.STRING, allowNull: true },
  department: { type: DataTypes.STRING, allowNull: true },
  submittedAt: { type: DataTypes.DATE, allowNull: true },
  reviewedAt: { type: DataTypes.DATE, allowNull: true },
  rejectionReason: { type: DataTypes.TEXT, allowNull: true },
  role: {
    type: DataTypes.ENUM('PASSENGER', 'DRIVER'),
    allowNull: false,
    defaultValue: 'PASSENGER',
  },
  activeMode: {
    type: DataTypes.ENUM('PASSENGER', 'DRIVER'),
    allowNull: false,
    defaultValue: 'PASSENGER',
  },
  driverProfile: {
    type: DataTypes.JSON,
    allowNull: true,
  },
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
  await ensureUserColumns();
  await User.sync();
}

async function ensureUserColumns() {
  const queryInterface = sequelize.getQueryInterface();
  let columns;
  try {
    columns = await queryInterface.describeTable('users');
  } catch (error) {
    if (error?.original?.errno === 1146) return;
    throw error;
  }

  const addColumn = async (name, definition) => {
    if (!columns[name]) {
      await queryInterface.addColumn('users', name, definition);
      columns[name] = {};
    }
  };

  await addColumn('student_card_url', {
    type: DataTypes.STRING(500),
    allowNull: true,
  });
  await addColumn('verification_status', {
    type: DataTypes.ENUM(
      'NOT_SUBMITTED',
      'PENDING',
      'APPROVED',
      'REJECTED',
      'REQUIRES_RESUBMISSION',
    ),
    allowNull: false,
    defaultValue: 'NOT_SUBMITTED',
  });
  await addColumn('student_id', { type: DataTypes.STRING, allowNull: true });
  await addColumn('faculty', { type: DataTypes.STRING, allowNull: true });
  await addColumn('department', { type: DataTypes.STRING, allowNull: true });
  await addColumn('submitted_at', { type: DataTypes.DATE, allowNull: true });
  await addColumn('reviewed_at', { type: DataTypes.DATE, allowNull: true });
  await addColumn('rejection_reason', { type: DataTypes.TEXT, allowNull: true });
  await addColumn('role', {
    type: DataTypes.ENUM('PASSENGER', 'DRIVER'),
    allowNull: false,
    defaultValue: 'PASSENGER',
  });
  await addColumn('active_mode', {
    type: DataTypes.ENUM('PASSENGER', 'DRIVER'),
    allowNull: false,
    defaultValue: 'PASSENGER',
  });
  await addColumn('driver_profile', {
    type: DataTypes.JSON,
    allowNull: true,
  });
}

function saveStudentCard(firebaseUid, body) {
  if (!body?.studentCard) return null;
  const allowedMimeTypes = new Set([
    'image/jpeg',
    'image/png',
    'image/webp',
  ]);
  const mimeType = String(body.studentCardMimeType || '').toLowerCase();
  if (!allowedMimeTypes.has(mimeType)) {
    const error = new Error('Student card must be a JPG, PNG or WEBP image.');
    error.statusCode = 400;
    throw error;
  }

  let bytes;
  try {
    bytes = Buffer.from(body.studentCard, 'base64');
  } catch (_error) {
    const error = new Error('Invalid student card upload.');
    error.statusCode = 400;
    throw error;
  }
  if (!bytes.length || bytes.length > 5 * 1024 * 1024) {
    const error = new Error('Student card image must be smaller than 5 MB.');
    error.statusCode = 400;
    throw error;
  }
  const isJpeg = bytes.length >= 3 &&
    bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  const isPng = bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes.subarray(1, 4).toString() === 'PNG';
  const isWebp = bytes.length >= 12 &&
    bytes.subarray(0, 4).toString('ascii') === 'RIFF' &&
    bytes.subarray(8, 12).toString('ascii') === 'WEBP';
  if (!isJpeg && !isPng && !isWebp) {
    const error = new Error(
      'The uploaded student card is not a valid JPG, PNG or WEBP image.',
    );
    error.statusCode = 400;
    throw error;
  }

  const extension = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
  }[mimeType];
  const uploadDirectory = path.join(process.cwd(), 'uploads', 'student-cards');
  fs.mkdirSync(uploadDirectory, { recursive: true });
  const fileName = `${firebaseUid}-${Date.now()}${extension}`;
  fs.writeFileSync(path.join(uploadDirectory, fileName), bytes);
  return `/uploads/student-cards/${fileName}`;
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

  const studentCardUrl = saveStudentCard(decodedToken.uid, body);
  const existingUser = await User.findOne({
    where: { firebaseUid: decodedToken.uid },
  });
  if (!studentCardUrl && (!existingUser || !existingUser.studentCardUrl)) {
    const error = new Error('A student card is required for verification.');
    error.statusCode = 400;
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
      studentCardUrl,
      verificationStatus: 'PENDING',
      role: 'PASSENGER',
      activeMode: 'PASSENGER',
      driverProfile: null,
    },
  });

  if (!created) {
    if (user.accountType !== validation.accountType) {
      const error = new Error('Le type de compte ne correspond pas au domaine email.');
      error.statusCode = 409;
      throw error;
    }
    const updates = {
      fullName: body.fullName?.trim() || user.fullName,
      email: validation.email,
      emailVerified: decodedToken.email_verified === true,
      verificationStatus: user.universityVerified ? 'APPROVED' : 'PENDING',
    };
    if (studentCardUrl) updates.studentCardUrl = studentCardUrl;
    await user.update(updates);
  }

  return user;
}

function getProfile(decodedToken) {
  const email = normalizeEmail(decodedToken.email);
  const validation = validateUniversityEmail(email);
  if (!validation.valid) {
    const error = new Error(
      'Adresse universitaire non autorisee. Utilisez edu.uiz.ac.ma ou uiz.ac.ma.',
    );
    error.statusCode = 403;
    throw error;
  }
  return User.findOne({ where: { firebaseUid: decodedToken.uid } });
}

async function verifyUniversity(decodedToken) {
  await ensureSchema();
  if (decodedToken.email_verified !== true) {
    const error = new Error('Verify your university email before continuing.');
    error.statusCode = 403;
    throw error;
  }

  const email = normalizeEmail(decodedToken.email);
  const validation = validateUniversityEmail(email);
  if (!validation.valid) {
    const error = new Error(
      'Adresse universitaire non autorisee. Utilisez edu.uiz.ac.ma ou uiz.ac.ma.',
    );
    error.statusCode = 403;
    throw error;
  }

  const [user, created] = await User.findOrCreate({
    where: { firebaseUid: decodedToken.uid },
    defaults: {
      firebaseUid: decodedToken.uid,
      fullName: decodedToken.name || email.split('@')[0],
      email: validation.email,
      accountType: validation.accountType,
      university: 'Universite Ibn Zohr',
      emailVerified: true,
      universityVerified: false,
      role: 'PASSENGER',
      activeMode: 'PASSENGER',
    },
  });
  if (!created) {
    await user.update({ emailVerified: true });
  }
  return user;
}

async function approveUniversity(firebaseUid) {
  await ensureSchema();
  const user = await User.findOne({ where: { firebaseUid } });
  if (!user) {
    const error = new Error('User profile not found.');
    error.statusCode = 404;
    throw error;
  }
  await user.update({
    universityVerified: true,
    verificationStatus: 'APPROVED',
  });
  return user;
}

async function activateDriver(decodedToken, driverProfile) {
  await ensureSchema();
  const user = await getProfile(decodedToken);
  if (!user) {
    const error = new Error('User profile not found.');
    error.statusCode = 404;
    throw error;
  }
  if (!user.universityVerified) {
    const error = new Error('University verification is required before activating Driver Mode.');
    error.statusCode = 403;
    throw error;
  }

  const requiredFields = [
    'drivingLicense',
    'vehicleBrand',
    'vehicleModel',
    'vehicleRegistration',
    'availableSeats',
  ];
  for (const field of requiredFields) {
    const value = driverProfile?.[field];
    if (value === undefined || value === null || String(value).trim() === '') {
      const error = new Error(`Driver information is missing: ${field}`);
      error.statusCode = 400;
      throw error;
    }
  }

  const availableSeats = Number(driverProfile.availableSeats);
  if (!Number.isInteger(availableSeats) || availableSeats < 1 || availableSeats > 8) {
    const error = new Error('Available seats must be a whole number between 1 and 8.');
    error.statusCode = 400;
    throw error;
  }

  await user.update({
    role: 'DRIVER',
    activeMode: 'DRIVER',
    driverProfile: {
      drivingLicense: String(driverProfile.drivingLicense).trim(),
      vehicleBrand: String(driverProfile.vehicleBrand).trim(),
      vehicleModel: String(driverProfile.vehicleModel).trim(),
      vehicleRegistration: String(driverProfile.vehicleRegistration).trim(),
      availableSeats,
    },
  });
  return user;
}

async function switchMode(decodedToken, activeMode) {
  await ensureSchema();
  const normalizedMode = String(activeMode || '').trim().toUpperCase();
  if (!['PASSENGER', 'DRIVER'].includes(normalizedMode)) {
    const error = new Error('Active mode must be PASSENGER or DRIVER.');
    error.statusCode = 400;
    throw error;
  }

  const user = await getProfile(decodedToken);
  if (!user) {
    const error = new Error('User profile not found.');
    error.statusCode = 404;
    throw error;
  }
  if (normalizedMode === 'DRIVER' && !user.universityVerified) {
    const error = new Error('University verification is required before activating Driver Mode.');
    error.statusCode = 403;
    throw error;
  }
  if (normalizedMode === 'DRIVER' && !user.driverProfile) {
    const error = new Error('Complete your driver information before activating Driver Mode.');
    error.statusCode = 403;
    throw error;
  }

  await user.update({ activeMode: normalizedMode });
  return user;
}

async function markEmailVerified(decodedToken) {
  const user = await getProfile(decodedToken);
  if (user && decodedToken.email_verified === true) {
    await user.update({ emailVerified: true });
  }
  return user;
}

module.exports = {
  User,
  syncProfile,
  getProfile,
  markEmailVerified,
  verifyUniversity,
  approveUniversity,
  activateDriver,
  switchMode,
};
