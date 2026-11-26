const { randomUUID } = require('node:crypto');
const { mkdir, open, readFile, unlink } = require('node:fs/promises');
const { join } = require('node:path');
const sequelize = require('../../config/database');
const Vehicle = require('../../models/vehicle');
const { findOwnerId, requireOwnerId } = require('../driver-owner');

const directory = join(__dirname, '../../../uploads/driver-vehicles');

function imagePath(key) {
  if (!/^[a-f0-9-]{36}$/.test(key)) throw new Error('Invalid stored vehicle image key');
  return join(directory, key);
}

async function removeImages(keys) {
  for (const key of keys) {
    if (!key) continue;
    try {
      await unlink(imagePath(key));
    } catch (error) {
      if (error.code !== 'ENOENT') console.error('Could not remove a private vehicle image', error.code);
    }
  }
}

async function storeImage(bytes, keys) {
  if (!bytes) return null;
  await mkdir(directory, { recursive: true });
  const key = randomUUID();
  const file = await open(imagePath(key), 'wx');
  keys.push(key);
  try {
    await file.writeFile(bytes);
  } finally {
    await file.close();
  }
  return key;
}

async function serialize(vehicle, includeRegistration = true) {
  const {
    id, make, model, color, year, registrationNumber, passengerCapacity,
    photoKey, registrationPhotoKey,
  } = vehicle;
  const [photo, registrationPhoto] = await Promise.all([
    photoKey ? readFile(imagePath(photoKey)) : null,
    includeRegistration && registrationPhotoKey ? readFile(imagePath(registrationPhotoKey)) : null,
  ]);
  return {
    id, make, model, color, year, registrationNumber, passengerCapacity,
    photo, registrationPhoto, hasRegistrationPhoto: Boolean(registrationPhotoKey),
  };
}

async function findRow(firebaseUid, id, transaction) {
  const ownerId = await findOwnerId(firebaseUid, transaction);
  if (!ownerId) return null;
  return Vehicle.findOne({
    where: { id, ownerId },
    transaction,
    lock: transaction?.LOCK.UPDATE,
  });
}

async function list(firebaseUid) {
  const ownerId = await findOwnerId(firebaseUid);
  if (!ownerId) return [];
  const vehicles = await Vehicle.findAll({ where: { ownerId } });
  return Promise.all(vehicles.map((vehicle) => serialize(vehicle, false)));
}

async function find(firebaseUid, id, { transaction, includeImages = true } = {}) {
  const vehicle = await findRow(firebaseUid, id, transaction);
  if (!vehicle) return undefined;
  return includeImages ? serialize(vehicle) : { passengerCapacity: vehicle.passengerCapacity };
}

async function create(firebaseUid, input) {
  const ownerId = await requireOwnerId(firebaseUid);
  const { photo, registrationPhoto, ...details } = input;
  const newKeys = [];
  let vehicle;
  try {
    const photoKey = await storeImage(photo, newKeys);
    const registrationPhotoKey = await storeImage(registrationPhoto, newKeys);
    vehicle = await Vehicle.create({ ...details, ownerId, photoKey, registrationPhotoKey });
  } catch (error) {
    await removeImages(newKeys);
    throw error;
  }
  return serialize(vehicle);
}

async function update(firebaseUid, id, input) {
  const { photo, registrationPhoto, ...changes } = input;
  const newKeys = [];
  const oldKeys = [];
  let vehicle;
  try {
    vehicle = await sequelize.transaction(async (transaction) => {
      const row = await findRow(firebaseUid, id, transaction);
      if (!row) return null;
      if (photo !== undefined) {
        oldKeys.push(row.photoKey);
        changes.photoKey = await storeImage(photo, newKeys);
      }
      if (registrationPhoto !== undefined) {
        oldKeys.push(row.registrationPhotoKey);
        changes.registrationPhotoKey = await storeImage(registrationPhoto, newKeys);
      }
      return row.update(changes, { transaction });
    });
  } catch (error) {
    await removeImages(newKeys);
    throw error;
  }
  await removeImages(oldKeys);
  return vehicle ? serialize(vehicle) : undefined;
}

async function remove(firebaseUid, id) {
  let vehicle;
  try {
    vehicle = await sequelize.transaction(async (transaction) => {
      const row = await findRow(firebaseUid, id, transaction);
      if (row) await row.destroy({ transaction });
      return row;
    });
  } catch (error) {
    if (error.original?.errno === 1451) {
      const message = 'A vehicle referenced by a trip cannot be deleted';
      throw Object.assign(new Error(message), { statusCode: 409, publicMessage: message });
    }
    throw error;
  }
  if (!vehicle) return false;
  await removeImages([vehicle.photoKey, vehicle.registrationPhotoKey]);
  return true;
}

module.exports = { list, find, create, update, remove };
