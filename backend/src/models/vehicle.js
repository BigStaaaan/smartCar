const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const { User } = require('../services/authentication/authentication.service');

const Vehicle = sequelize.define('Vehicle', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  ownerId: { type: DataTypes.UUID, allowNull: false },
  make: { type: DataTypes.STRING, allowNull: false },
  model: { type: DataTypes.STRING, allowNull: false },
  color: { type: DataTypes.STRING, allowNull: false },
  year: { type: DataTypes.SMALLINT.UNSIGNED, allowNull: true },
  registrationNumber: { type: DataTypes.STRING(16), allowNull: false },
  passengerCapacity: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  photoKey: { type: DataTypes.STRING, allowNull: true },
  registrationPhotoKey: { type: DataTypes.STRING, allowNull: true },
  verificationStatus: {
    type: DataTypes.ENUM('PENDING', 'APPROVED', 'REJECTED'),
    allowNull: false,
    defaultValue: 'PENDING',
  },
  createdAt: { type: DataTypes.DATE(3), allowNull: false },
  updatedAt: { type: DataTypes.DATE(3), allowNull: false },
}, {
  tableName: 'vehicles',
  underscored: true,
});

Vehicle.belongsTo(User, {
  as: 'owner',
  foreignKey: 'ownerId',
  onDelete: 'RESTRICT',
  onUpdate: 'RESTRICT',
});

module.exports = Vehicle;
