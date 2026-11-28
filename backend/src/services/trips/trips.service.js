const vehicles = require('../../repositories/vehicles/vehicles.repository');
const { tripsRepository } = require('../../repositories/trips/trips.repository');

function tripError(statusCode, publicMessage) {
  return Object.assign(new Error(publicMessage), { statusCode, publicMessage });
}

async function validateTripDetails(ownerId, details, transaction) {
  if (details.origin.toLowerCase() === details.destination.toLowerCase()) {
    throw tripError(400, 'Origin and destination must be different');
  }

  const vehicle = await vehicles.find(ownerId, details.vehicleId, {
    transaction, includeImages: false,
  });
  if (!vehicle) throw tripError(404, 'Vehicle not found');
  if (details.seats > vehicle.passengerCapacity) {
    throw tripError(400, 'Seats cannot exceed the vehicle passenger capacity');
  }
  if (Date.parse(details.departureAt) <= Date.now()) {
    throw tripError(400, 'Departure must be in the future');
  }
}

function publish(ownerId, details) {
  return tripsRepository.transaction(async (transaction) => {
    await validateTripDetails(ownerId, details, transaction);
    return tripsRepository.create(ownerId, {
      ...details,
      contributionDh: details.contributionDh || null,
    }, transaction);
  });
}

function withOwnedTrip(ownerId, id, operation) {
  return tripsRepository.transaction(async (transaction) => {
    const trip = await tripsRepository.find(ownerId, id, transaction);
    if (!trip) throw tripError(404, 'Trip not found');
    return operation(trip, transaction);
  });
}

function requireUpcomingTrip(trip, action) {
  if (trip.status !== 'published' || Date.parse(trip.details.departureAt) <= Date.now()) {
    throw tripError(409, `Only published trips with a future departure can be ${action}`);
  }
}

function update(ownerId, id, changes) {
  return withOwnedTrip(ownerId, id, async (trip, transaction) => {
    requireUpcomingTrip(trip, 'modified');
    const details = { ...trip.details, ...changes };
    await validateTripDetails(ownerId, details, transaction);
    requireUpcomingTrip(trip, 'modified');
    return tripsRepository.update(ownerId, id, {
      ...details,
      contributionDh: details.contributionDh || null,
    }, transaction);
  });
}

function cancel(ownerId, id) {
  return withOwnedTrip(ownerId, id, (trip, transaction) => {
    requireUpcomingTrip(trip, 'cancelled');
    return tripsRepository.setStatus(ownerId, id, 'cancelled', transaction);
  });
}

function start(ownerId, id) {
  return withOwnedTrip(ownerId, id, (trip, transaction) => {
    const departureReached = Date.parse(trip.details.departureAt) <= Date.now();
    if (trip.status !== 'published' || !departureReached) {
      throw tripError(409, 'Only published trips at or after their scheduled departure can be started');
    }
    return tripsRepository.setStatus(ownerId, id, 'in_progress', transaction);
  });
}

function complete(ownerId, id) {
  return withOwnedTrip(ownerId, id, (trip, transaction) => {
    if (trip.status !== 'in_progress') {
      throw tripError(409, 'Only trips in progress can be completed');
    }
    return tripsRepository.setStatus(ownerId, id, 'completed', transaction);
  });
}

module.exports = { publish, update, cancel, start, complete };
