const { tripsRepository } = require('../../repositories/trips/trips.repository');

const service = require('../../services/trips/trips.service');

function tripResponse(trip) {
  const { origin, destination, departureAt, vehicleId, seats, contributionDh } = trip.details;
  return {
    id: trip.id,
    status: trip.status,
    details: { origin, destination, departureAt, vehicleId, seats, contributionDh: contributionDh ?? null },
  };
}

async function list(req, res) {
  const trips = await tripsRepository.list(req.user.uid);
  return res.json(trips.map(tripResponse));
}

async function get(req, res) {
  const trip = await tripsRepository.find(req.user.uid, req.params.id);
  if (!trip) return res.status(404).json({ error: 'Trip not found' });
  return res.json(tripResponse(trip));
}

async function create(req, res) {
  const trip = await service.publish(req.user.uid, req.body);
  return res.status(201).json(tripResponse(trip));
}

async function update(req, res) {
  const trip = await service.update(req.user.uid, req.params.id, req.body);
  return res.json(tripResponse(trip));
}

module.exports = { list, get, create, update };
