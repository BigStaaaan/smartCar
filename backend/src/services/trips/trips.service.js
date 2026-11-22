const vehicles = require('../../repositories/vehicles/vehicles.repository');
const { tripsRepository } = require('../../repositories/trips/trips.repository');

function tripError(statusCode, publicMessage) {
  return Object.assign(new Error(publicMessage), { statusCode, publicMessage });
}

async function publish(ownerId, details) {
  if (details.origin.toLowerCase() === details.destination.toLowerCase()) {
    throw tripError(400, 'Origin and destination must be different');
  }

  const vehicle = await vehicles.find(ownerId, details.vehicleId);
  if (!vehicle) throw tripError(404, 'Vehicle not found');
  if (details.seats > vehicle.passengerCapacity) {
    throw tripError(400, 'Seats cannot exceed the vehicle passenger capacity');
  }
  if (Date.parse(details.departureAt) <= Date.now()) {
    throw tripError(400, 'Departure must be in the future');
  }

  return tripsRepository.create(ownerId, {
    ...details,
    contributionDh: details.contributionDh || null,
  });
}

module.exports = { publish };
