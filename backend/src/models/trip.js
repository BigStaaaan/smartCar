const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const { User } = require('../services/authentication/authentication.service');
const Vehicle = require('./vehicle');

const Trip = sequelize.define('Trip', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  driverId: { type: DataTypes.UUID, allowNull: false },
  vehicleId: { type: DataTypes.UUID, allowNull: false },
  origin: { type: DataTypes.TEXT, allowNull: false },
  destination: { type: DataTypes.TEXT, allowNull: false },
  departureAt: { type: DataTypes.DATE(3), allowNull: false },
  seats: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  contributionDh: { type: DataTypes.TINYINT.UNSIGNED, allowNull: true },
  status: {
    type: DataTypes.ENUM('published', 'in_progress', 'completed', 'cancelled'),
    allowNull: false,
    defaultValue: 'published',
  },
  createdAt: { type: DataTypes.DATE(3), allowNull: false },
  updatedAt: { type: DataTypes.DATE(3), allowNull: false },
}, {
  tableName: 'trips',
  underscored: true,
});

Trip.belongsTo(User, {
  as: 'driver',
  foreignKey: 'driverId',
  onDelete: 'RESTRICT',
  onUpdate: 'RESTRICT',
});

// The migration enforces the composite key (vehicle_id, driver_id).
Trip.belongsTo(Vehicle, { as: 'vehicle', foreignKey: 'vehicleId', constraints: false });
Vehicle.hasMany(Trip, { as: 'trips', foreignKey: 'vehicleId', constraints: false });

module.exports = Trip;
