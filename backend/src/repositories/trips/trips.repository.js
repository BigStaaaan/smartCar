const { randomUUID } = require('node:crypto');

function createTripsRepository(initialTrips = []) {
  const trips = new Map(initialTrips.map((trip) => [trip.id, trip]));

  function list(ownerId) {
    return [...trips.values()].filter((trip) => trip.ownerId === ownerId);
  }

  function find(ownerId, id) {
    const trip = trips.get(id);
    return trip?.ownerId === ownerId ? trip : undefined;
  }

  function create(ownerId, details) {
    const trip = { id: randomUUID(), ownerId, status: 'published', details };
    trips.set(trip.id, trip);
    return trip;
  }

  return { list, find, create };
}

module.exports = { createTripsRepository, tripsRepository: createTripsRepository() };
