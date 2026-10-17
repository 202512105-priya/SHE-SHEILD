import React, { useState } from 'react';

export default function App() {
  const [stats] = useState({
    activeAlerts: 3,
    totalProtectedUsers: 1420,
    resolvedComplaints: 289,
    safeZonesMonitored: 45
  });

  const [incidents] = useState([
    { id: 'INC-8091', type: 'Emergency SOS Broadcast', user: 'Verified User #921', status: 'DISPATCHED', priority: 'CRITICAL', time: '5 mins ago' },
    { id: 'INC-8090', type: 'Travel Transit Deviation', user: 'Verified User #410', status: 'INVESTIGATING', priority: 'HIGH', time: '18 mins ago' },
    { id: 'INC-8089', type: 'Cyber Harassment Complaint', user: 'Verified User #105', status: 'UNDER REVIEW', priority: 'MEDIUM', time: '1 hour ago' },
  ]);

  return (
    <div className="admin-container" style={{ padding: '24px', fontFamily: 'sans-serif', background: '#faf5ff', minHeight: '100vh' }}>
      <header style={{ marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ color: '#581c87', margin: 0 }}>SHE SHIELD â€” Central Administrator Command Dashboard</h1>
          <p style={{ color: '#7e22ce', margin: '4px 0 0 0' }}>Real-time Emergency & Cybercrime Operations Panel</p>
        </div>
        <span style={{ background: '#22c55e', color: 'white', padding: '6px 14px', borderRadius: '20px', fontSize: '13px', fontWeight: 'bold' }}>
          SYSTEM OPERATIONAL
        </span>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '32px' }}>
        <div style={{ padding: '20px', background: '#fff', borderRadius: '12px', borderLeft: '5px solid #ef4444', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
          <h4 style={{ margin: 0, color: '#6b7280' }}>Active SOS Alerts</h4>
          <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#dc2626', margin: '8px 0 0 0' }}>{stats.activeAlerts}</p>
        </div>
        <div style={{ padding: '20px', background: '#fff', borderRadius: '12px', borderLeft: '5px solid #a855f7', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
          <h4 style={{ margin: 0, color: '#6b7280' }}>Protected Users</h4>
          <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#7c3aed', margin: '8px 0 0 0' }}>{stats.totalProtectedUsers}</p>
        </div>
        <div style={{ padding: '20px', background: '#fff', borderRadius: '12px', borderLeft: '5px solid #22c55e', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
          <h4 style={{ margin: 0, color: '#6b7280' }}>Resolved Cases</h4>
          <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#16a34a', margin: '8px 0 0 0' }}>{stats.resolvedComplaints}</p>
        </div>
        <div style={{ padding: '20px', background: '#fff', borderRadius: '12px', borderLeft: '5px solid #0ea5e9', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
          <h4 style={{ margin: 0, color: '#6b7280' }}>Safe Zones Monitored</h4>
          <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#0284c7', margin: '8px 0 0 0' }}>{stats.safeZonesMonitored}</p>
        </div>
      </div>

      <div style={{ background: '#fff', borderRadius: '12px', padding: '20px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
        <h2 style={{ color: '#374151', marginTop: 0 }}>Live Emergency Incidents & Intake Desk</h2>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid #e5e7eb', color: '#6b7280', fontSize: '13px' }}>
              <th style={{ padding: '12px' }}>INCIDENT ID</th>
              <th style={{ padding: '12px' }}>TYPE</th>
              <th style={{ padding: '12px' }}>USER</th>
              <th style={{ padding: '12px' }}>PRIORITY</th>
              <th style={{ padding: '12px' }}>STATUS</th>
              <th style={{ padding: '12px' }}>TIME</th>
            </tr>
          </thead>
          <tbody>
            {incidents.map((inc) => (
              <tr key={inc.id} style={{ borderBottom: '1px solid #f3f4f6' }}>
                <td style={{ padding: '12px', fontWeight: 'bold', color: '#6b21a8' }}>{inc.id}</td>
                <td style={{ padding: '12px' }}>{inc.type}</td>
                <td style={{ padding: '12px' }}>{inc.user}</td>
                <td style={{ padding: '12px' }}>
                  <span style={{
                    padding: '4px 8px', borderRadius: '6px', fontSize: '12px', fontWeight: 'bold',
                    background: inc.priority === 'CRITICAL' ? '#fee2e2' : inc.priority === 'HIGH' ? '#ffedd5' : '#fef9c3',
                    color: inc.priority === 'CRITICAL' ? '#b91c1c' : inc.priority === 'HIGH' ? '#c2410c' : '#854d0e',
                  }}>{inc.priority}</span>
                </td>
                <td style={{ padding: '12px' }}>
                  <span style={{ padding: '4px 8px', borderRadius: '6px', fontSize: '12px', background: '#f3e8ff', color: '#6b21a8', fontWeight: 'bold' }}>
                    {inc.status}
                  </span>
                </td>
                <td style={{ padding: '12px', color: '#6b7280' }}>{inc.time}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
