const { Sequelize } = require('sequelize');
const environment = require('./environment');

const sequelize = new Sequelize(environment.databaseUrl, {
  dialect: 'postgres',
  logging: environment.nodeEnv === 'development' ? console.log : false,
});

module.exports = sequelize;