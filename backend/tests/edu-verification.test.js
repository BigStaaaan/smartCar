const { requireAdmin } = require('../src/middlewares/auth.middleware');
const { requireVerifiedMember } = require('../src/middlewares/verification.middleware');

describe('EDU Verification Security & Authorization Middleware', () => {
  function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
  }

  test('requireAdmin blocks regular users with 403', () => {
    const req = { user: { uid: 'u1', role: 'PASSENGER' } };
    const res = mockRes();
    const next = jest.fn();
    requireAdmin(req, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });

  test('requireAdmin allows ADMIN and SUPPORT roles', () => {
    for (const role of ['ADMIN', 'SUPPORT']) {
      const req = { user: { uid: 'a1', role } };
      const res = mockRes();
      const next = jest.fn();
      requireAdmin(req, res, next);
      expect(next).toHaveBeenCalled();
    }
  });

  test('requireVerifiedMember blocks unverified email with 403', async () => {
    const req = { user: { uid: 'u1', email_verified: false } };
    const res = mockRes();
    const next = jest.fn();
    await requireVerifiedMember(req, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });
});
