const admin = require('firebase-admin');
const environment = require('./environment');
const path = require('path');

if (!admin.apps.length) {
  if (environment.googleApplicationCredentials) {
    const credentialPath = path.isAbsolute(environment.googleApplicationCredentials)
      ? environment.googleApplicationCredentials
      : path.resolve(__dirname, '../..', environment.googleApplicationCredentials);
    admin.initializeApp({
      credential: admin.credential.cert(require(credentialPath)),
    });
  } else if (
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