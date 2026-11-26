const repository = require('../../repositories/vehicles/vehicles.repository');

function vehicleResponse(vehicle, includeRegistration = false) {
  const { ownerId, photo, registrationPhoto, hasRegistrationPhoto, ...details } = vehicle;
  const response = {
    ...details,
    year: details.year ?? null,
    photo: photo?.toString('base64') ?? null,
    hasRegistrationPhoto: hasRegistrationPhoto ?? Boolean(registrationPhoto),
  };
  if (includeRegistration) {
    response.registrationPhoto = registrationPhoto?.toString('base64') ?? null;
  }
  return response;
}

function notFound(res) {
  return res.status(404).json({ error: 'Vehicle not found' });
}

async function list(req, res) {
  const vehicles = await repository.list(req.user.uid);
  return res.json(vehicles.map((vehicle) => vehicleResponse(vehicle)));
}

async function get(req, res) {
  const vehicle = await repository.find(req.user.uid, req.params.id);
  return vehicle ? res.json(vehicleResponse(vehicle, true)) : notFound(res);
}

async function create(req, res) {
  const vehicle = await repository.create(req.user.uid, req.body);
  return res.status(201).json(vehicleResponse(vehicle, true));
}

async function update(req, res) {
  const { removePhoto, removeRegistrationPhoto, ...changes } = req.body;
  if (removePhoto) changes.photo = null;
  if (removeRegistrationPhoto) changes.registrationPhoto = null;

  const vehicle = await repository.update(req.user.uid, req.params.id, changes);
  return vehicle ? res.json(vehicleResponse(vehicle, true)) : notFound(res);
}

async function remove(req, res) {
  const deleted = await repository.remove(req.user.uid, req.params.id);
  return deleted ? res.status(204).end() : notFound(res);
}

module.exports = { list, get, create, update, remove };
