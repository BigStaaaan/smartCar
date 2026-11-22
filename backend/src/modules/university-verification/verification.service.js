const fs = require('fs');
const path = require('path');
const { DataTypes, Op } = require('sequelize');
const sequelize = require('../../config/database');
const { User } = require('../../services/authentication/authentication.service');

const VerificationAudit = sequelize.models.VerificationAudit ||
  sequelize.define('VerificationAudit', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    firebaseUid: { type: DataTypes.STRING, allowNull: false },
    action: {
      type: DataTypes.ENUM('SUBMITTED', 'APPROVED', 'REJECTED', 'RESUBMISSION'),
      allowNull: false,
    },
    actorUid: { type: DataTypes.STRING, allowNull: true },
    reason: { type: DataTypes.TEXT, allowNull: true },
  }, {
    tableName: 'verification_audits',
    underscored: true,
  });

async function ensureSchema() {
  await sequelize.authenticate();
  await User.sync();
  await VerificationAudit.sync();
}

function publicRequest(user) {
  if (!user) return null;
  return {
    firebaseUid: user.firebaseUid,
    fullName: user.fullName,
    email: user.email,
    accountType: user.accountType,
    university: user.university,
    studentId: user.studentId,
    faculty: user.faculty,
    department: user.department,
    studentCardUrl: user.studentCardUrl,
    status: user.verificationStatus || 'NOT_SUBMITTED',
    submittedAt: user.submittedAt,
    reviewedAt: user.reviewedAt,
    rejectionReason: user.rejectionReason,
  };
}

async function getStatus(decodedToken) {
  await ensureSchema();
  const user = await User.findOne({ where: { firebaseUid: decodedToken.uid } });
  return publicRequest(user);
}

async function submitRequest(decodedToken, body, file) {
  await ensureSchema();
  if (!file) {
    const error = new Error('A student card image is required.');
    error.statusCode = 400;
    throw error;
  }
  const bytes = file.buffer;
  const isJpeg = bytes.length >= 3 &&
    bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  const isPng = bytes.length >= 8 &&
    bytes[0] === 0x89 && bytes.subarray(1, 4).toString('hex') === '504e47';
  const isWebp = bytes.length >= 12 &&
    bytes.subarray(0, 4).toString('ascii') === 'RIFF' &&
    bytes.subarray(8, 12).toString('ascii') === 'WEBP';
  if (!isJpeg && !isPng && !isWebp) {
    const error = new Error('The uploaded file is not a valid JPEG, PNG or WEBP image.');
    error.statusCode = 400;
    throw error;
  }

  const user = await User.findOne({ where: { firebaseUid: decodedToken.uid } });
  if (!user) {
    const error = new Error('User profile not found.');
    error.statusCode = 404;
    throw error;
  }

  const studentId = String(body.studentId || '').trim();
  const university = String(body.university || user.university || '').trim();
  const faculty = String(body.faculty || '').trim();
  const department = String(body.department || '').trim();
  if (!studentId || !university || !faculty) {
    const error = new Error('Student ID, university and faculty are required.');
    error.statusCode = 400;
    throw error;
  }

  const uploadDirectory = path.join(process.cwd(), 'private', 'student-cards');
  fs.mkdirSync(uploadDirectory, { recursive: true });
  const extension = file.mimetype === 'image/png'
    ? '.png'
    : file.mimetype === 'image/webp'
      ? '.webp'
      : '.jpg';
  const fileName = `${decodedToken.uid}-${Date.now()}${extension}`;
  const filePath = path.join(uploadDirectory, fileName);
  fs.writeFileSync(filePath, file.buffer);

  await user.update({
    university,
    studentId,
    faculty,
    department,
    studentCardUrl: filePath,
    verificationStatus: 'PENDING',
    submittedAt: new Date(),
    reviewedAt: null,
    rejectionReason: null,
    universityVerified: false,
  });
  await VerificationAudit.create({
    firebaseUid: decodedToken.uid,
    action: 'SUBMITTED',
    actorUid: decodedToken.uid,
  });
  return publicRequest(user);
}

async function listRequests(status) {
  await ensureSchema();
  const where = {};
  if (status && status !== 'ALL') where.verificationStatus = status;
  const users = await User.findAll({
    where,
    order: [['submitted_at', 'DESC']],
  });
  return users.map(publicRequest);
}

async function getRequest(firebaseUid) {
  await ensureSchema();
  const user = await User.findOne({ where: { firebaseUid } });
  if (!user) {
    const error = new Error('Verification request not found.');
    error.statusCode = 404;
    throw error;
  }
  const audits = await VerificationAudit.findAll({
    where: { firebaseUid },
    order: [['created_at', 'DESC']],
  });
  return {
    request: publicRequest(user),
    auditHistory: audits.map((audit) => ({
      id: audit.id,
      action: audit.action,
      actorUid: audit.actorUid,
      reason: audit.reason,
      createdAt: audit.createdAt,
    })),
  };
}

async function decideRequest(firebaseUid, actorUid, decision, reason) {
  await ensureSchema();
  const user = await User.findOne({ where: { firebaseUid } });
  if (!user) {
    const error = new Error('Verification request not found.');
    error.statusCode = 404;
    throw error;
  }

  const normalizedDecision = String(decision || '').toUpperCase();
  if (!['APPROVED', 'REJECTED', 'REQUIRES_RESUBMISSION'].includes(normalizedDecision)) {
    const error = new Error('Decision must be APPROVED, REJECTED or REQUIRES_RESUBMISSION.');
    error.statusCode = 400;
    throw error;
  }
  if (normalizedDecision !== 'APPROVED' && !String(reason || '').trim()) {
    const error = new Error('A rejection reason is required.');
    error.statusCode = 400;
    throw error;
  }

  await user.update({
    verificationStatus: normalizedDecision,
    universityVerified: normalizedDecision === 'APPROVED',
    reviewedAt: new Date(),
    rejectionReason: normalizedDecision === 'APPROVED'
      ? null
      : String(reason).trim(),
  });
  await VerificationAudit.create({
    firebaseUid,
    action: normalizedDecision === 'APPROVED'
      ? 'APPROVED'
      : 'REJECTED',
    actorUid,
    reason: normalizedDecision === 'APPROVED' ? null : String(reason).trim(),
  });
  return publicRequest(user);
}

async function getPrivateCard(firebaseUid) {
  await ensureSchema();
  const user = await User.findOne({ where: { firebaseUid } });
  if (!user?.studentCardUrl) {
    const error = new Error('Student card not found.');
    error.statusCode = 404;
    throw error;
  }
  const filePath = path.resolve(user.studentCardUrl);
  if (!fs.existsSync(filePath)) {
    const error = new Error('Student card file not found.');
    error.statusCode = 404;
    throw error;
  }
  return filePath;
}

module.exports = {
  VerificationAudit,
  publicRequest,
  getStatus,
  submitRequest,
  listRequests,
  getRequest,
  decideRequest,
  getPrivateCard,
};
