import React, { useState } from 'react';

export default function App() {
  const [stats] = useState({
    activeAlerts: 3,
    totalProtectedUsers: 1420,
    resolvedComplaints: 289,
    safeZonesMonitored: 45
  });

  return (
    <div className="admin-container" style={{ padding: '24px', fontFamily: 'sans-serif' }}>
      <header style={{ marginBottom: '32px' }}>
        <h1 style={{ color: '#6b21a8' }}>SHE SHIELD â€” Central Administrator Command Dashboard</h1>
      </header>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px' }}>
        <div style={{ padding: '16px', background: '#fee2e2', borderRadius: '8px' }}>
          <h3>Active Emergency Alerts</h3>
          <p style={{ fontSize: '28px', fontWeight: 'bold', color: '#dc2626' }}>{stats.activeAlerts}</p>
        </div>
        <div style={{ padding: '16px', background: '#f3e8ff', borderRadius: '8px' }}>
          <h3>Protected App Users</h3>
          <p style={{ fontSize: '28px', fontWeight: 'bold', color: '#7c3aed' }}>{stats.totalProtectedUsers}</p>
        </div>
        <div style={{ padding: '16px', background: '#dcfce7', borderRadius: '8px' }}>
          <h3>Resolved Reports</h3>
          <p style={{ fontSize: '28px', fontWeight: 'bold', color: '#16a34a' }}>{stats.resolvedComplaints}</p>
        </div>
        <div style={{ padding: '16px', background: '#e0f2fe', borderRadius: '8px' }}>
          <h3>Monitored Geo-Zones</h3>
          <p style={{ fontSize: '28px', fontWeight: 'bold', color: '#0284c7' }}>{stats.safeZonesMonitored}</p>
        </div>
      </div>
    </div>
  );
}
