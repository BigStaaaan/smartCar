require('dotenv').config();
const firebase = require('../src/config/firebase');

async function main() {
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;

  if (!email || !password) {
    throw new Error(
      'Set ADMIN_EMAIL and ADMIN_PASSWORD before running this script.',
    );
  }
  if (password.length < 6) {
    throw new Error('ADMIN_PASSWORD must contain at least 6 characters.');
  }

  let user;
  try {
    user = await firebase.auth().getUserByEmail(email);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    user = await firebase.auth().createUser({
      email,
      password,
      emailVerified: true,
      disabled: false,
    });
  }

  await firebase.auth().updateUser(user.uid, {
    password,
    emailVerified: true,
    disabled: false,
  });

  await firebase.auth().setCustomUserClaims(user.uid, {
    admin: true,
    role: 'ADMIN',
  });

  console.log(`Admin created: ${email}`);
  console.log(`UID: ${user.uid}`);
  console.log('Sign out and sign in again to refresh admin claims.');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
