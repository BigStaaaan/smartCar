import {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';

export function signInAdmin(email: string, password: string) {
  return signInWithEmailAndPassword(getAuth(), email, password);
}

export function signOutAdmin() {
  return signOut(getAuth());
}
