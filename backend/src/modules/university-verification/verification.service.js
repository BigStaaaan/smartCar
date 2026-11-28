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

const University = sequelize.models.University ||
  sequelize.define('University', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    name: { type: DataTypes.STRING, allowNull: false, unique: true },
    emailDomains: { type: DataTypes.TEXT, allowNull: true },
    isActive: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  }, {
    tableName: 'universities',
    underscored: true,
  });

const UniversityVerificationRequest = sequelize.models.UniversityVerificationRequest ||
  sequelize.define('UniversityVerificationRequest', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    userId: { type: DataTypes.UUID, allowNull: true },
    firebaseUid: { type: DataTypes.STRING, allowNull: false },
    accountType: {
      type: DataTypes.ENUM('student', 'staff'),
      allowNull: false,
    },
    universityId: { type: DataTypes.UUID, allowNull: true },
    universityName: { type: DataTypes.STRING, allowNull: false },
    universityEmail: { type: DataTypes.STRING, allowNull: false },
    documentStoragePath: { type: DataTypes.STRING, allowNull: false },
    profilePhotoStoragePath: { type: DataTypes.STRING, allowNull: true },
    universityEmailVerified: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
    status: {
      type: DataTypes.ENUM('pending', 'approved', 'declined'),
      allowNull: false,
      defaultValue: 'pending',
    },
    rejectionReason: { type: DataTypes.TEXT, allowNull: true },
    reviewedBy: { type: DataTypes.STRING, allowNull: true },
    reviewedAt: { type: DataTypes.DATE, allowNull: true },
    submittedAt: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
  }, {
    tableName: 'university_verification_requests',
    underscored: true,
  });

const UniversityEmailChallenge = sequelize.models.UniversityEmailChallenge ||
  sequelize.define('UniversityEmailChallenge', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    firebaseUid: { type: DataTypes.STRING, allowNull: false },
    universityId: { type: DataTypes.UUID, allowNull: true },
    universityName: { type: DataTypes.STRING, allowNull: false },
    universityEmail: { type: DataTypes.STRING, allowNull: false },
    code: { type: DataTypes.STRING(12), allowNull: false },
    verified: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
    expiresAt: { type: DataTypes.DATE, allowNull: false },
  }, {
    tableName: 'university_email_challenges',
    underscored: true,
  });

const DEFAULT_UNIVERSITIES = [
  { name: 'Université des Sciences et de la Technologie Houari Boumediene (USTHB)', emailDomains: JSON.stringify(['usthb.dz', 'etu.usthb.dz']) },
  { name: "Université d'Alger 1 Benyoucef Benkhedda", emailDomains: JSON.stringify(['univ-alger.dz']) },
  { name: 'École Nationale Polytechnique (ENP)', emailDomains: JSON.stringify(['g.enp.edu.dz', 'enp.edu.dz']) },
  { name: 'Université Frères Mentouri Constantine 1', emailDomains: JSON.stringify(['umc.edu.dz']) },
  { name: "Université d'Oran 1 Ahmed Ben Bella", emailDomains: JSON.stringify(['univ-oran1.dz']) },
  { name: 'Université Abderrahmane Mira de Béjaïa', emailDomains: JSON.stringify(['univ-bejaia.dz']) },
];

let schemaReady = false;
async function ensureSchema() {
  if (schemaReady) return;
  await sequelize.authenticate();
  await User.sync();
  await University.sync();
  await UniversityVerificationRequest.sync();
  await UniversityEmailChallenge.sync();
  await VerificationAudit.sync();
  const count = await University.count();
  if (count === 0) {
    await University.bulkCreate(DEFAULT_UNIVERSITIES);
  }
  schemaReady = true;
}

function parseDomains(raw) {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw;
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return String(raw).split(',').map((s) => s.trim()).filter(Boolean);
  }
}

function normalizeStatus(status) {
  const s = String(status || '').toLowerCase();
  if (s === 'approved') return 'approved';
  if (s === 'pending') return 'pending';
  if (s === 'rejected' || s === 'declined' || s === 'requires_resubmission') return 'declined';
  return 'not_submitted';
}

function publicRequest(user, latestRequest = null) {
  if (!user && !latestRequest) return null;
  const rawStatus = latestRequest?.status || user?.verificationStatus || 'NOT_SUBMITTED';
  const normalized = normalizeStatus(rawStatus);
  return {
    id: latestRequest?.id || null,
    firebaseUid: latestRequest?.firebaseUid || user?.firebaseUid,
    fullName: user?.fullName || null,
    email: user?.email || null,
    accountType: latestRequest?.accountType || (user?.accountType ? String(user.accountType).toLowerCase() : null),
    universityId: latestRequest?.universityId || null,
    university: latestRequest?.universityName || user?.university || null,
    universityEmail: latestRequest?.universityEmail || null,
    studentId: user?.studentId || null,
    faculty: user?.faculty || null,
    department: user?.department || null,
    hasDocument: Boolean(latestRequest?.documentStoragePath || user?.studentCardUrl),
    status: normalized,
    verificationStatus: user?.verificationStatus || 'NOT_SUBMITTED',
    submittedAt: latestRequest?.submittedAt || user?.submittedAt || null,
    reviewedAt: latestRequest?.reviewedAt || user?.reviewedAt || null,
    reviewedBy: latestRequest?.reviewedBy || null,
    rejectionReason: latestRequest?.rejectionReason ?? user?.rejectionReason ?? null,
  };
}

async function listUniversities({ includeInactive = false } = {}) {
  await ensureSchema();
  const where = includeInactive ? {} : { isActive: true };
  const rows = await University.findAll({ where, order: [['name', 'ASC']] });
  return rows.map((u) => ({
    id: u.id,
    name: u.name,
    emailDomains: parseDomains(u.emailDomains),
    isActive: u.isActive,
  }));
}

async function createUniversity({ name, emailDomains }) {
  await ensureSchema();
  const trimmedName = String(name || '').trim();
  if (!trimmedName) {
    const error = new Error('University name is required.');
    error.statusCode = 400;
    throw error;
  }
  const domains = parseDomains(emailDomains);
  const created = await University.create({
    name: trimmedName,
    emailDomains: domains.length ? JSON.stringify(domains) : null,
    isActive: true,
  });
  return {
    id: created.id,
    name: created.name,
    emailDomains: domains,
    isActive: created.isActive,
  };
}

async function updateUniversity(id, { name, emailDomains, isActive }) {
  await ensureSchema();
  const uni = await University.findByPk(id);
  if (!uni) {
    const error = new Error('University not found.');
    error.statusCode = 404;
    throw error;
  }
  const updates = {};
  if (name !== undefined) updates.name = String(name).trim();
  if (emailDomains !== undefined) {
    const domains = parseDomains(emailDomains);
    updates.emailDomains = domains.length ? JSON.stringify(domains) : null;
  }
  if (isActive !== undefined) updates.isActive = Boolean(isActive);
  await uni.update(updates);
  return {
    id: uni.id,
    name: uni.name,
    emailDomains: parseDomains(uni.emailDomains),
    isActive: uni.isActive,
  };
}

async function findUniversityByEmail(email) {
  const normalized = String(email || '').trim().toLowerCase();
  if (!normalized.includes('@')) return null;
  const domain = normalized.split('@')[1];
  const universities = await University.findAll({ where: { isActive: true } });
  for (const uni of universities) {
    const domains = parseDomains(uni.emailDomains);
    if (domains.some((d) => domain === d.toLowerCase() || domain.endsWith(`.${d.toLowerCase()}`))) {
      return uni;
    }
  }
  return null;
}

async function getStatus(decodedToken) {
  await ensureSchema();
  const user = await User.findOne({ where: { firebaseUid: decodedToken.uid } });
  if (!user) return null;
  const latestRequest = await UniversityVerificationRequest.findOne({
    where: { firebaseUid: decodedToken.uid },
    order: [['submittedAt', 'DESC']],
  });
  const base = publicRequest(user, latestRequest);
  const matchedUniversity = await findUniversityByEmail(decodedToken.email || user.email);
  const challenge = await UniversityEmailChallenge.findOne({
    where: { firebaseUid: decodedToken.uid },
    order: [['created_at', 'DESC']],
  });

  let flowState = base.status;
  if (decodedToken.email_verified !== true) {
    flowState = 'email_verification_required';
  } else if (base.status === 'not_submitted') {
    if (matchedUniversity) {
      flowState = 'profile_completion_required';
    } else if (challenge?.verified) {
      flowState = 'profile_completion_required';
    } else if (challenge && new Date(challenge.expiresAt) > new Date()) {
      flowState = 'university_email_verification_required';
    } else {
      flowState = 'university_email_required';
    }
  }

  return {
    ...base,
    flowState,
    isUniversityRegistrationEmail: Boolean(matchedUniversity),
    matchedUniversity: matchedUniversity
      ? { id: matchedUniversity.id, name: matchedUniversity.name, emailDomains: parseDomains(matchedUniversity.emailDomains) }
      : null,
    verifiedUniversityEmail: matchedUniversity
      ? (decodedToken.email || user.email)
      : (challenge?.verified ? challenge.universityEmail : base.universityEmail),
    pendingUniversityEmail: challenge && !challenge.verified ? challenge.universityEmail : null,
  };
}

async function requestUniversityEmailVerification(decodedToken, { universityId, universityEmail }) {
  await ensureSchema();
  const email = String(universityEmail || '').trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email || !emailRegex.test(email)) {
    const error = new Error('Valid university email is required.');
    error.statusCode = 400;
    throw error;
  }
  let uni = null;
  if (universityId) {
    uni = await University.findByPk(universityId);
  } else {
    uni = await findUniversityByEmail(email);
  }
  if (!uni || !uni.isActive) {
    const error = new Error('Selected university is invalid or inactive.');
    error.statusCode = 400;
    throw error;
  }
  const domains = parseDomains(uni.emailDomains);
  if (domains.length > 0) {
    const domain = email.split('@')[1];
    const ok = domains.some((d) => domain === d.toLowerCase() || domain.endsWith(`.${d.toLowerCase()}`));
    if (!ok) {
      const error = new Error(`University email must belong to: ${domains.join(', ')}`);
      error.statusCode = 400;
      throw error;
    }
  }
  const code = String(Math.floor(100000 + Math.random() * 900000));
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
  await UniversityEmailChallenge.create({
    firebaseUid: decodedToken.uid,
    universityId: uni.id,
    universityName: uni.name,
    universityEmail: email,
    code,
    verified: false,
    expiresAt,
  });
  return {
    universityId: uni.id,
    universityName: uni.name,
    universityEmail: email,
    expiresAt,
    message: 'Verification code sent to university email.',
  };
}

async function confirmUniversityEmailVerification(decodedToken, { code }) {
  await ensureSchema();
  const challenge = await UniversityEmailChallenge.findOne({
    where: { firebaseUid: decodedToken.uid },
    order: [['created_at', 'DESC']],
  });
  if (!challenge || challenge.verified) {
    const error = new Error('No pending university email verification found.');
    error.statusCode = 400;
    throw error;
  }
  if (new Date(challenge.expiresAt) < new Date()) {
    const error = new Error('Verification code has expired.');
    error.statusCode = 400;
    throw error;
  }
  if (String(code || '').trim() !== challenge.code) {
    const error = new Error('Invalid verification code.');
    error.statusCode = 400;
    throw error;
  }
  await challenge.update({ verified: true });
  return {
    verified: true,
    universityId: challenge.universityId,
    universityName: challenge.universityName,
    universityEmail: challenge.universityEmail,
  };
}

async function submitRequest(decodedToken, body, file) {
  await ensureSchema();
  if (!file) {
    const error = new Error('A university identification document image is required.');
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

  const existingPending = await UniversityVerificationRequest.findOne({
    where: { firebaseUid: decodedToken.uid, status: 'pending' },
  });
  if (existingPending) {
    const error = new Error('A verification request is already pending review.');
    error.statusCode = 409;
    throw error;
  }

  const accountType = String(body.accountType || 'student').trim().toLowerCase();
  if (!['student', 'staff'].includes(accountType)) {
    const error = new Error('Account type must be student or staff.');
    error.statusCode = 400;
    throw error;
  }

  const universityId = body.universityId ? String(body.universityId).trim() : null;
  let universityRecord = null;
  if (universityId) {
    universityRecord = await University.findByPk(universityId);
    if (!universityRecord || !universityRecord.isActive) {
      const error = new Error('Selected university is invalid or inactive.');
      error.statusCode = 400;
      throw error;
    }
  }

  const universityName = universityRecord?.name || String(body.university || user.university || '').trim();
  const universityEmail = String(body.universityEmail || '').trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!universityName || !universityEmail || !emailRegex.test(universityEmail)) {
    const error = new Error('Valid university and university email are required.');
    error.statusCode = 400;
    throw error;
  }

  if (universityRecord) {
    const allowedDomains = parseDomains(universityRecord.emailDomains);
    if (allowedDomains.length > 0) {
      const emailDomain = universityEmail.split('@')[1];
      const matches = allowedDomains.some((d) => emailDomain === d.toLowerCase() || emailDomain.endsWith(`.${d.toLowerCase()}`));
      if (!matches) {
        const error = new Error(`University email must belong to one of the configured domains: ${allowedDomains.join(', ')}`);
        error.statusCode = 400;
        throw error;
      }
    }
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

  const now = new Date();
  const previousCount = await UniversityVerificationRequest.count({
    where: { firebaseUid: decodedToken.uid },
  });

  const createdRequest = await UniversityVerificationRequest.create({
    userId: user.id,
    firebaseUid: decodedToken.uid,
    accountType,
    universityId: universityRecord?.id || null,
    universityName,
    universityEmail,
    documentStoragePath: filePath,
    status: 'pending',
    submittedAt: now,
  });

  await user.update({
    accountType: accountType.toUpperCase(),
    university: universityName,
    studentId: body.studentId ? String(body.studentId).trim() : user.studentId,
    faculty: body.faculty ? String(body.faculty).trim() : user.faculty,
    department: body.department ? String(body.department).trim() : user.department,
    studentCardUrl: filePath,
    verificationStatus: 'PENDING',
    submittedAt: now,
    reviewedAt: null,
    rejectionReason: null,
    universityVerified: false,
  });

  await VerificationAudit.create({
    firebaseUid: decodedToken.uid,
    action: previousCount > 0 ? 'RESUBMISSION' : 'SUBMITTED',
    actorUid: decodedToken.uid,
  });

  return publicRequest(user, createdRequest);
}

async function listRequests(filters = {}) {
  await ensureSchema();
  const statusFilter = typeof filters === 'string' ? filters : filters.status;
  const universityId = typeof filters === 'object' ? filters.universityId : null;
  const accountType = typeof filters === 'object' ? filters.accountType : null;
  const search = typeof filters === 'object' ? String(filters.search || '').trim().toLowerCase() : '';

  const where = {};
  if (statusFilter && statusFilter.toUpperCase() !== 'ALL') {
    const normalized = normalizeStatus(statusFilter);
    if (['pending', 'approved', 'declined'].includes(normalized)) {
      where.status = normalized;
    }
  }
  if (universityId) where.universityId = universityId;
  if (accountType && ['student', 'staff'].includes(accountType.toLowerCase())) {
    where.accountType = accountType.toLowerCase();
  }

  const requests = await UniversityVerificationRequest.findAll({
    where,
    order: [['submittedAt', 'DESC']],
  });

  const uids = [...new Set(requests.map((r) => r.firebaseUid))];
  const users = uids.length
    ? await User.findAll({ where: { firebaseUid: { [Op.in]: uids } } })
    : [];
  const userMap = new Map(users.map((u) => [u.firebaseUid, u]));

  let results = requests.map((reqRow) => publicRequest(userMap.get(reqRow.firebaseUid), reqRow));
  if (search) {
    results = results.filter((item) =>
      [item.fullName, item.email, item.universityEmail, item.university]
        .filter(Boolean)
        .some((val) => val.toLowerCase().includes(search)),
    );
  }
  return results;
}

async function getRequest(firebaseUid) {
  await ensureSchema();
  const user = await User.findOne({ where: { firebaseUid } });
  if (!user) {
    const error = new Error('Verification request not found.');
    error.statusCode = 404;
    throw error;
  }
  const attempts = await UniversityVerificationRequest.findAll({
    where: { firebaseUid },
    order: [['submittedAt', 'DESC']],
  });
  const audits = await VerificationAudit.findAll({
    where: { firebaseUid },
    order: [['created_at', 'DESC']],
  });
  return {
    request: publicRequest(user, attempts[0] || null),
    attempts: attempts.map((a) => publicRequest(user, a)),
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

  const rawDecision = String(decision || '').trim().toUpperCase();
  const isApproved = rawDecision === 'APPROVED';
  const isDeclined = ['DECLINED', 'REJECTED', 'REQUIRES_RESUBMISSION'].includes(rawDecision);
  if (!isApproved && !isDeclined) {
    const error = new Error('Decision must be APPROVED or DECLINED.');
    error.statusCode = 400;
    throw error;
  }
  if (isDeclined && !String(reason || '').trim()) {
    const error = new Error('A rejection reason is required.');
    error.statusCode = 400;
    throw error;
  }

  const now = new Date();
  const trimmedReason = isApproved ? null : String(reason).trim();

  const latestRequest = await UniversityVerificationRequest.findOne({
    where: { firebaseUid },
    order: [['submittedAt', 'DESC']],
  });
  if (latestRequest) {
    await latestRequest.update({
      status: isApproved ? 'approved' : 'declined',
      rejectionReason: trimmedReason,
      reviewedBy: actorUid,
      reviewedAt: now,
    });
  }

  await user.update({
    verificationStatus: isApproved ? 'APPROVED' : 'REJECTED',
    universityVerified: isApproved,
    reviewedAt: now,
    rejectionReason: trimmedReason,
  });

  await VerificationAudit.create({
    firebaseUid,
    action: isApproved ? 'APPROVED' : 'REJECTED',
    actorUid,
    reason: trimmedReason,
  });

  return publicRequest(user, latestRequest);
}

async function getPrivateCard(firebaseUid) {
  await ensureSchema();
  const latestRequest = await UniversityVerificationRequest.findOne({
    where: { firebaseUid },
    order: [['submittedAt', 'DESC']],
  });
  const user = await User.findOne({ where: { firebaseUid } });
  const cardPath = latestRequest?.documentStoragePath || user?.studentCardUrl;
  if (!cardPath) {
    const error = new Error('Identification document not found.');
    error.statusCode = 404;
    throw error;
  }
  const filePath = path.resolve(cardPath);
  if (!fs.existsSync(filePath)) {
    const error = new Error('Identification document file not found.');
    error.statusCode = 404;
    throw error;
  }
  return filePath;
}

async function getPrivateProfilePhoto(firebaseUid) {
  await ensureSchema();
  const latestRequest = await UniversityVerificationRequest.findOne({
    where: { firebaseUid },
    order: [['submittedAt', 'DESC']],
  });
  const photoPath = latestRequest?.profilePhotoStoragePath;
  if (!photoPath) {
    const error = new Error('Profile photo not found.');
    error.statusCode = 404;
    throw error;
  }
  const filePath = path.resolve(photoPath);
  if (!fs.existsSync(filePath)) {
    const error = new Error('Profile photo file not found.');
    error.statusCode = 404;
    throw error;
  }
  return filePath;
}

module.exports = {
  VerificationAudit,
  University,
  UniversityVerificationRequest,
  UniversityEmailChallenge,
  publicRequest,
  listUniversities,
  createUniversity,
  updateUniversity,
  getStatus,
  requestUniversityEmailVerification,
  confirmUniversityEmailVerification,
  submitRequest,
  listRequests,
  getRequest,
  decideRequest,
  getPrivateCard,
  getPrivateProfilePhoto,
};
