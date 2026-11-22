import { Outlet } from 'react-router-dom';
import { signOutAdmin } from '../../services/auth.service';
import './layout.css';

export default function AdminLayout() {
  return (
    <div className="admin-shell">
      <aside className="admin-sidebar">
        <div className="admin-brand">
          <span className="brand-mark" aria-hidden="true">S</span>
          <span>SmartCar</span>
        </div>
        <nav className="admin-nav" aria-label="Administration">
          <span className="admin-nav-active">Verification</span>
        </nav>
        <button className="signout" onClick={() => signOutAdmin()}>
          Sign out
        </button>
      </aside>
      <main className="admin-main">
        <header className="admin-topbar">
          <h1>University verification</h1>
        </header>
        <Outlet />
      </main>
    </div>
  );
}
