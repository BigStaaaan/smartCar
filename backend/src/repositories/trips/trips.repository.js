function createTripsRepository(initialTrips = []) {
  const trips = new Map(initialTrips.map((trip) => [trip.id, trip]));

  function list(ownerId) {
    return [...trips.values()].filter((trip) => trip.ownerId === ownerId);
  }

  function find(ownerId, id) {
    const trip = trips.get(id);
    return trip?.ownerId === ownerId ? trip : undefined;
  }

  return { list, find };
}

module.exports = { createTripsRepository, tripsRepository: createTripsRepository() };
