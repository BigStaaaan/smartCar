const admin = require('firebase-admin');
const environment = require('./environment');

if (!admin.apps.length) {
  if (
    environment.firebase.projectId &&
    environment.firebase.clientEmail &&
    environment.firebase.privateKey
  ) {
    admin.initializeApp({
      credential: admin.credential.cert(environment.firebase),
    });
  } else {
    admin.initializeApp();
  }
}

module.exports = admin;