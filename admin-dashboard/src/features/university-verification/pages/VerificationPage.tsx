import { useEffect, useState } from 'react';
import { api } from '../../../services/api';
import './verification.css';

type Request = {
  id: string | null;
  firebaseUid: string;
  fullName: string;
  email: string;
  accountType: string;
  universityId: string | null;
  university: string;
  universityEmail: string | null;
  studentId: string | null;
  faculty: string | null;
  department: string | null;
  status: 'not_submitted' | 'pending' | 'approved' | 'declined';
  submittedAt: string | null;
  rejectionReason: string | null;
};

export default function VerificationPage() {
  const [status, setStatus] = useState('pending');
  const [accountTypeFilter, setAccountTypeFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [requests, setRequests] = useState<Request[]>([]);
  const [allRequests, setAllRequests] = useState<Request[]>([]);
  const [selected, setSelected] = useState<Request | null>(null);
  const [cardUrl, setCardUrl] = useState('');
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  async function loadRequests(nextStatus = status) {
    setLoading(true);
    try {
      const response = await api.get('/verification/admin/requests', {
        params: {
          status: 'ALL',
          accountType: accountTypeFilter !== 'all' ? accountTypeFilter : undefined,
          search: searchQuery.trim() || undefined,
        },
      });
      const all = (response.data.requests as Request[]) ?? [];
      setAllRequests(all);
      const visible =
        nextStatus === 'all'
          ? all
          : all.filter((request) => request.status === nextStatus);
      setRequests(visible);
      setSelected((current) =>
        visible.find((request) =>
          request.firebaseUid === current?.firebaseUid,
        ) ?? visible[0] ?? null,
      );
      setCardUrl('');
    } catch {
      setMessage('Unable to load verification requests.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadRequests(status);
  }, [status, accountTypeFilter]);

  async function openRequest(request: Request) {
    setSelected(request);
    setReason('');
    setCardUrl('');
    try {
      const response = await api.get(
        `/verification/admin/requests/${request.firebaseUid}/card`,
        { responseType: 'blob' },
      );
      setCardUrl(URL.createObjectURL(response.data));
    } catch {
      setMessage('The student card could not be loaded.');
    }
  }

  async function decide(decision: 'APPROVED' | 'REJECTED' | 'REQUIRES_RESUBMISSION') {
    if (!selected) return;
    if (decision !== 'APPROVED' && !reason.trim()) {
      setMessage('A rejection reason is required.');
      return;
    }
    setLoading(true);
    setMessage('');
    try {
      await api.post(
        `/verification/admin/requests/${selected.firebaseUid}/decision`,
        { decision, reason },
      );
      setMessage(
        decision === 'APPROVED'
          ? 'Verification approved.'
          : 'Verification rejected.',
      );
      await loadRequests(status);
    } catch (error: unknown) {
      setMessage(
        (error as { response?: { data?: { error?: string } } }).response?.data?.error ||
          'The decision could not be saved.',
      );
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => () => {
    if (cardUrl) URL.revokeObjectURL(cardUrl);
  }, [cardUrl]);

  useEffect(() => {
    if (selected) openRequest(selected);
  }, [selected?.firebaseUid]);

  return (
    <section className="verification-page">
      <div className="verification-heading">
        <div>
          <p className="verification-eyebrow">University operations</p>
          <h1>Student verification</h1>
        </div>
        <label className="status-filter">
          <span>Status</span>
          <select value={status} onChange={(event) => setStatus(event.target.value)}>
            <option value="PENDING">Pending review</option>
            <option value="APPROVED">Approved</option>
            <option value="REJECTED">Rejected</option>
            <option value="REQUIRES_RESUBMISSION">Resubmission</option>
            <option value="ALL">All requests</option>
          </select>
        </label>
      </div>
      <div className="verification-summary" aria-label="Verification queue summary">
        <div>
          <span>Pending</span>
          <strong>{allRequests.filter((item) => item.status === 'pending').length}</strong>
        </div>
        <div>
          <span>Approved</span>
          <strong>{allRequests.filter((item) => item.status === 'approved').length}</strong>
        </div>
        <div>
          <span>Declined</span>
          <strong>{allRequests.filter((item) => item.status === 'declined').length}</strong>
        </div>
      </div>
      {message && <p className="verification-message">{message}</p>}
      <div className="verification-grid">
        <div className="request-list">
          <div className="request-list-header">
            <span>{status === 'all' ? 'All requests' : status === 'pending' ? 'Pending review' : status}</span>
            <strong>{loading ? '—' : requests.length}</strong>
          </div>
          {requests.map((request) => (
            <button
              type="button"
              key={request.firebaseUid}
              className={selected?.firebaseUid === request.firebaseUid ? 'request-row selected' : 'request-row'}
              onClick={() => openRequest(request)}
            >
              <span>
                <strong>{request.fullName}</strong>
                <small>{request.email}</small>
              </span>
              <span className={`status status-${request.status.toLowerCase()}`}>{request.status}</span>
            </button>
          ))}
          {!loading && requests.length === 0 && (
            <p className="empty-state">No verification requests in this status.</p>
          )}
        </div>
        <aside className="request-detail">
          {selected ? (
            <>
              <h2>{selected.fullName}</h2>
              <dl>
                <div><dt>University</dt><dd>{selected.university}</dd></div>
                <div><dt>Student ID</dt><dd>{selected.studentId || '-'}</dd></div>
                <div><dt>Faculty</dt><dd>{selected.faculty || '-'}</dd></div>
                <div><dt>Department</dt><dd>{selected.department || '-'}</dd></div>
              </dl>
              {cardUrl
                ? <img className="student-card" src={cardUrl} alt={`Student card for ${selected.fullName}`} />
                : <div className="card-loading">Student card preview</div>}
              <label className="reason-field">
                Rejection reason
                <textarea
                  value={reason}
                  onChange={(event) => setReason(event.target.value)}
                  placeholder="Explain why the card was rejected"
                />
              </label>
              <div className="decision-actions">
                <button
                  type="button"
                  className="approve"
                  disabled={loading}
                  onClick={() => decide('APPROVED')}
                >
                  Approve
                </button>
                <button
                  type="button"
                  className="reject"
                  disabled={loading}
                  onClick={() => decide('REJECTED')}
                >
                  Reject
                </button>
                <button
                  type="button"
                  className="resubmit"
                  disabled={loading}
                  onClick={() => decide('REQUIRES_RESUBMISSION')}
                >
                  Request resubmission
                </button>
              </div>
            </>
          ) : (
            <p className="empty-detail">Select a request to review the student card.</p>
          )}
        </aside>
      </div>
    </section>
  );
}
