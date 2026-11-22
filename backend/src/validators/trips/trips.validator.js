const Joi = require('joi');

const departurePattern = /^(\d{4}-\d{2}-\d{2})T(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d(?:\.\d+)?)?(?:Z|[+-]\d{2}:\d{2})$/;

const create = Joi.object({
  origin: Joi.string().trim().required(),
  destination: Joi.string().trim().required(),
  departureAt: Joi.string().trim().required().custom((value, helpers) => {
    const date = departurePattern.exec(value)?.[1];
    const departure = new Date(value);
    if (!date || !Number.isFinite(departure.getTime()) ||
        new Date(`${date}T00:00:00.000Z`).toISOString().slice(0, 10) !== date) {
      return helpers.message({ custom: 'departureAt must be a valid ISO 8601 date and time with an explicit time zone' });
    }
    return departure.toISOString();
  }),
  vehicleId: Joi.string().trim().required(),
  seats: Joi.number().integer().min(1).required(),
  contributionDh: Joi.number().integer().min(0).max(40).allow(null),
}).required().unknown(false);

module.exports = { create };
