const vehicles = require('../../repositories/vehicles/vehicles.repository');
const { tripsRepository } = require('../../repositories/trips/trips.repository');

function tripError(statusCode, publicMessage) {
  return Object.assign(new Error(publicMessage), { statusCode, publicMessage });
}

function validateTripDetails(ownerId, details) {
  if (details.origin.toLowerCase() === details.destination.toLowerCase()) {
    throw tripError(400, 'Origin and destination must be different');
  }

  const vehicle = vehicles.find(ownerId, details.vehicleId);
  if (!vehicle) throw tripError(404, 'Vehicle not found');
  if (details.seats > vehicle.passengerCapacity) {
    throw tripError(400, 'Seats cannot exceed the vehicle passenger capacity');
  }
  if (Date.parse(details.departureAt) <= Date.now()) {
    throw tripError(400, 'Departure must be in the future');
  }
}

function publish(ownerId, details) {
  validateTripDetails(ownerId, details);
  return tripsRepository.create(ownerId, {
    ...details,
    contributionDh: details.contributionDh || null,
  });
}

function findOwnedTrip(ownerId, id) {
  const trip = tripsRepository.find(ownerId, id);
  if (!trip) throw tripError(404, 'Trip not found');
  return trip;
}

function findUpcomingTrip(ownerId, id, action) {
  const trip = findOwnedTrip(ownerId, id);
  if (trip.status !== 'published' || Date.parse(trip.details.departureAt) <= Date.now()) {
    throw tripError(409, `Only published trips with a future departure can be ${action}`);
  }
  return trip;
}

function update(ownerId, id, changes) {
  const trip = findUpcomingTrip(ownerId, id, 'modified');
  const details = { ...trip.details, ...changes };
  validateTripDetails(ownerId, details);
  return tripsRepository.update(ownerId, id, {
    ...details,
    contributionDh: details.contributionDh || null,
  });
}

function cancel(ownerId, id) {
  findUpcomingTrip(ownerId, id, 'cancelled');
  return tripsRepository.setStatus(ownerId, id, 'cancelled');
}

function start(ownerId, id) {
  const trip = findOwnedTrip(ownerId, id);
  const departureReached = Date.parse(trip.details.departureAt) <= Date.now();
  if (trip.status !== 'published' || !departureReached) {
    throw tripError(409, 'Only published trips at or after their scheduled departure can be started');
  }
  return tripsRepository.setStatus(ownerId, id, 'in_progress');
}

function complete(ownerId, id) {
  const trip = findOwnedTrip(ownerId, id);
  if (trip.status !== 'in_progress') {
    throw tripError(409, 'Only trips in progress can be completed');
  }
  return tripsRepository.setStatus(ownerId, id, 'completed');
}

module.exports = { publish, update, cancel, start, complete };
