const sequelize = require('../../config/database');
const Trip = require('../../models/trip');
const { findOwnerId, requireOwnerId } = require('../driver-owner');

function serialize(trip) {
  const { id, status, origin, destination, departureAt, vehicleId, seats, contributionDh } = trip;
  return {
    id,
    status,
    details: { origin, destination, departureAt: departureAt.toISOString(), vehicleId, seats, contributionDh },
  };
}

async function findRow(firebaseUid, id, transaction) {
  const driverId = await findOwnerId(firebaseUid, transaction);
  if (!driverId) return null;
  return Trip.findOne({
    where: { id, driverId },
    transaction,
    lock: transaction?.LOCK.UPDATE,
  });
}

async function list(firebaseUid) {
  const driverId = await findOwnerId(firebaseUid);
  if (!driverId) return [];
  const trips = await Trip.findAll({ where: { driverId } });
  return trips.map(serialize);
}

async function find(firebaseUid, id, transaction) {
  const trip = await findRow(firebaseUid, id, transaction);
  return trip ? serialize(trip) : undefined;
}

async function create(firebaseUid, details, transaction) {
  const driverId = await requireOwnerId(firebaseUid, transaction);
  return serialize(await Trip.create({ ...details, driverId }, { transaction }));
}

async function update(firebaseUid, id, details, transaction) {
  const trip = await findRow(firebaseUid, id, transaction);
  return trip ? serialize(await trip.update(details, { transaction })) : undefined;
}

async function setStatus(firebaseUid, id, status, transaction) {
  const trip = await findRow(firebaseUid, id, transaction);
  return trip ? serialize(await trip.update({ status }, { transaction })) : undefined;
}

function transaction(operation) {
  return sequelize.transaction(operation);
}

module.exports = { tripsRepository: { list, find, create, update, setStatus, transaction } };
