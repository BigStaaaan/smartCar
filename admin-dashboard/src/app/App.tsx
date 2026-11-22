import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { onAuthStateChanged } from 'firebase/auth';
import { getAuth } from 'firebase/auth';
import { useEffect, useState } from 'react';
import LoginPage from '../features/authentication/pages/LoginPage';
import VerificationPage from '../features/university-verification/pages/VerificationPage';
import AdminLayout from '../components/layout/AdminLayout';

export default function App() {
  const [ready, setReady] = useState(false);
  const [signedIn, setSignedIn] = useState(false);

  useEffect(() => {
    return onAuthStateChanged(getAuth(), async (user) => {
      if (!user) {
        setSignedIn(false);
        setReady(true);
        return;
      }
      const token = await user.getIdTokenResult(true);
      setSignedIn(token.claims.admin === true || token.claims.role === 'ADMIN');
      setReady(true);
    });
  }, []);

  if (!ready) return <div className="app-loading">Loading</div>;

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={signedIn ? <AdminLayout /> : <Navigate to="/login" replace />}
        >
          <Route index element={<Navigate to="/verification" replace />} />
          <Route path="verification" element={<VerificationPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}