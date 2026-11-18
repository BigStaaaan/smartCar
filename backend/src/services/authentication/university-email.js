const environment = require('../../config/environment');

function normalizeEmail(email) {
  return typeof email === 'string' ? email.trim().toLowerCase() : '';
}

function getDomain(email) {
  const normalized = normalizeEmail(email);
  const atIndex = normalized.lastIndexOf('@');
  return atIndex === -1 ? '' : normalized.slice(atIndex + 1);
}

function getAccountTypeFromEmail(email) {
  const domain = getDomain(email);
  if (domain === environment.studentEmailDomain) return 'STUDENT';
  if (domain === environment.staffEmailDomain) return 'STAFF';
  return null;
}

function validateUniversityEmail(email, accountType) {
  const normalized = normalizeEmail(email);
  const derivedType = getAccountTypeFromEmail(normalized);

  if (!derivedType) {
    return { valid: false, email: normalized, accountType: null };
  }
  if (accountType && accountType !== derivedType) {
    return { valid: false, email: normalized, accountType: derivedType };
  }
  return { valid: true, email: normalized, accountType: derivedType };
}

module.exports = {
  normalizeEmail,
  getDomain,
  getAccountTypeFromEmail,
  validateUniversityEmail,
};
