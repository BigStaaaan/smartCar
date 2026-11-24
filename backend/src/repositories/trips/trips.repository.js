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

  function update(ownerId, id, details) {
    const trip = find(ownerId, id);
    if (!trip) return undefined;
    const updated = { ...trip, details };
    trips.set(id, updated);
    return updated;
  }

  function setStatus(ownerId, id, status) {
    const trip = find(ownerId, id);
    if (!trip) return undefined;
    const updated = { ...trip, status };
    trips.set(id, updated);
    return updated;
  }

  return { list, find, create, update, setStatus };
}

module.exports = { createTripsRepository, tripsRepository: createTripsRepository() };
