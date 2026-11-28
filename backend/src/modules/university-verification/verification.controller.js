async function listUniversities(req, res) {
  const service = req.verificationService;
  const includeInactive = req.query.includeInactive === 'true';
  const universities = await service.listUniversities({ includeInactive });
  return res.json({ universities });
}

async function createUniversity(req, res) {
  const service = req.verificationService;
  const university = await service.createUniversity(req.body);
  return res.status(201).json({ university });
}

async function updateUniversity(req, res) {
  const service = req.verificationService;
  const university = await service.updateUniversity(req.params.id, req.body);
  return res.json({ university });
}

async function getStatus(req, res) {
  const service = req.verificationService;
  const request = await service.getStatus(req.user);
  return res.json({ request });
}

async function requestUniversityEmailVerification(req, res) {
  const service = req.verificationService;
  const result = await service.requestUniversityEmailVerification(req.user, req.body);
  return res.json(result);
}

async function confirmUniversityEmailVerification(req, res) {
  const service = req.verificationService;
  const result = await service.confirmUniversityEmailVerification(req.user, req.body);
  return res.json(result);
}

async function submitRequest(req, res) {
  const service = req.verificationService;
  const request = await service.submitRequest(req.user, req.body, req.files || req.file);
  return res.status(201).json({ request });
}

async function listRequests(req, res) {
  const service = req.verificationService;
  const requests = await service.listRequests({
    status: req.query.status,
    universityId: req.query.universityId,
    accountType: req.query.accountType,
    search: req.query.search,
  });
  return res.json({ requests });
}

async function getRequest(req, res) {
  const service = req.verificationService;
  const result = await service.getRequest(req.params.firebaseUid);
  return res.json(result);
}

async function decideRequest(req, res) {
  const service = req.verificationService;
  const request = await service.decideRequest(
    req.params.firebaseUid,
    req.user.uid,
    req.body.decision,
    req.body.reason,
  );
  return res.json({ request });
}

async function previewCard(req, res) {
  const service = req.verificationService;
  const filePath = await service.getPrivateCard(req.params.firebaseUid);
  return res.sendFile(filePath);
}

async function previewProfilePhoto(req, res) {
  const service = req.verificationService;
  const filePath = await service.getPrivateProfilePhoto(req.params.firebaseUid);
  return res.sendFile(filePath);
}

module.exports = {
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
  previewCard,
  previewProfilePhoto,
};
