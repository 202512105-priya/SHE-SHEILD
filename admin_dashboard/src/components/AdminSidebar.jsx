import React from 'react';

export default function AdminSidebar() {
  const navItems = [
    { label: "Dashboard Overview", path: "/overview" },
    { label: "Active SOS Monitor", path: "/sos" },
    { label: "Cyber Reports Desk", path: "/complaints" }
  ];

  return (
    <aside style={{ width: '240px', background: '#3b0764', color: 'white', padding: '20px' }}>
      <h3 style={{ color: '#d8b4fe' }}>SHE SHIELD OPS</h3>
      <nav>
        {navItems.map((item) => (
          <div key={item.path} style={{ padding: '10px 0', borderBottom: '1px solid #581c87' }}>
            {item.label}
          </div>
        ))}
      </nav>
    </aside>
  );
}
