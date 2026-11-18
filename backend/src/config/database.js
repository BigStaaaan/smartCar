const { Sequelize } = require('sequelize');
const environment = require('./environment');

const databaseUrl =
  environment.databaseUrl ||
  'mysql://root:@127.0.0.1:3306/smartcar';

const sequelize = new Sequelize(databaseUrl, {
  dialect: 'mysql',
  logging: environment.nodeEnv === 'development' ? console.log : false,
});

module.exports = sequelize;