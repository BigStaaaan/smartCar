const Joi = require('joi');

const maxImageBytes = 2 * 1024 * 1024;
const platePattern = /^(\d{1,5})\s*(?:\|\s*)?([A-Za-z]|(?=\p{L})[\u0600-\u06ff])\s*(?:\|\s*)?(\d{1,2})$/u;

const fields = Joi.object({
  make: Joi.string().trim(),
  model: Joi.string().trim(),
  color: Joi.string().trim(),
  year: Joi.number().integer().min(1900).max(new Date().getFullYear() + 1).allow(null),
  registrationNumber: Joi.string().trim().custom((value, helpers) => {
    const match = value.match(platePattern);
    if (!match) {
      return helpers.message({ custom: 'Invalid Moroccan registration number' });
    }
    const [, serial, letter, province] = match;
    return `${serial} | ${letter.toUpperCase()} | ${province}`;
  }),
  passengerCapacity: Joi.number().integer().min(1),
  photo: Joi.binary().strict().min(1).max(maxImageBytes),
  registrationPhoto: Joi.binary().strict().min(1).max(maxImageBytes),
}).unknown(false);

const create = fields.fork(
  ['make', 'model', 'color', 'registrationNumber', 'passengerCapacity'],
  (field) => field.required(),
);

const update = fields.keys({
  removePhoto: Joi.boolean().valid(true),
  removeRegistrationPhoto: Joi.boolean().valid(true),
}).oxor('photo', 'removePhoto')
  .oxor('registrationPhoto', 'removeRegistrationPhoto')
  .min(1);

module.exports = { create, update, maxImageBytes };
