const {
  normalizeEmail,
  getAccountTypeFromEmail,
  validateUniversityEmail,
} = require('../src/services/authentication/university-email');

describe('UIZ university email validation', () => {
  test('normalizes surrounding whitespace and lowercase', () => {
    expect(normalizeEmail('  Student@edu.uiz.ac.ma  '))
      .toBe('student@edu.uiz.ac.ma');
  });

  test('accepts exact student and staff domains', () => {
    expect(getAccountTypeFromEmail('student@edu.uiz.ac.ma')).toBe('STUDENT');
    expect(getAccountTypeFromEmail('employee@uiz.ac.ma')).toBe('STAFF');
  });

  test('rejects deceptive and unauthorized domains', () => {
    expect(getAccountTypeFromEmail('user@gmail.com')).toBeNull();
    expect(getAccountTypeFromEmail('user@uiz.ac.ma.fake.com')).toBeNull();
  });

  test('rejects mismatched account type and domain', () => {
    expect(validateUniversityEmail('student@edu.uiz.ac.ma', 'STAFF').valid)
      .toBe(false);
    expect(validateUniversityEmail('employee@uiz.ac.ma', 'STUDENT').valid)
      .toBe(false);
  });
});
