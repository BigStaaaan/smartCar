const admin = require('firebase-admin');
const environment = require('./environment');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(environment.firebase),
  });
}

module.exports = admin;