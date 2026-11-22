import { Outlet } from 'react-router-dom';
import { signOutAdmin } from '../../services/auth.service';
import './layout.css';

export default function AdminLayout() {
  return (
    <div className="admin-shell">
      <aside className="admin-sidebar">
        <div className="admin-brand">SmartCar</div>
        <nav><span className="admin-nav-active">University verification</span></nav>
        <button className="signout" onClick={() => signOutAdmin()}>Sign out</button>
      </aside>
      <main className="admin-main">
        <header className="admin-topbar"><h1>University verification</h1></header>
        <Outlet />
      </main>
    </div>
  );
}
