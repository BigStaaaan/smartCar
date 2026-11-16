const app = require('./src/app');
const environment = require('./src/config/environment');

app.listen(environment.port, () => {
  console.log(`SmartCar API listening on port ${environment.port}`);
});