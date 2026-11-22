const { randomUUID } = require('node:crypto');

const vehicles = new Map();

function list(ownerId) {
  return [...vehicles.values()].filter((vehicle) => vehicle.ownerId === ownerId);
}

function find(ownerId, id) {
  const vehicle = vehicles.get(id);
  return vehicle?.ownerId === ownerId ? vehicle : undefined;
}

function create(ownerId, details) {
  const vehicle = { ...details, id: randomUUID(), ownerId };
  vehicles.set(vehicle.id, vehicle);
  return vehicle;
}

function update(ownerId, id, changes) {
  const vehicle = find(ownerId, id);
  if (!vehicle) return undefined;
  const updated = { ...vehicle, ...changes, id, ownerId };
  vehicles.set(id, updated);
  return updated;
}

function remove(ownerId, id) {
  return find(ownerId, id) ? vehicles.delete(id) : false;
}

module.exports = { list, find, create, update, remove };
