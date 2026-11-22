async function getStatus(req, res) {
  const service = req.verificationService;
  const request = await service.getStatus(req.user);
  return res.json({ request });
}

async function submitRequest(req, res) {
  const service = req.verificationService;
  const request = await service.submitRequest(req.user, req.body, req.file);
  return res.status(201).json({ request });
}

async function listRequests(req, res) {
  const service = req.verificationService;
  const requests = await service.listRequests(req.query.status);
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

module.exports = {
  getStatus,
  submitRequest,
  listRequests,
  getRequest,
  decideRequest,
  previewCard,
};
