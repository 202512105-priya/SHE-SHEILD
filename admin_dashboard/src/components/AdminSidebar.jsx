import React from 'react';

export default function AdminSidebar() {
  const navItems = [
    { label: "Dashboard Overview", path: "/overview" },
    { label: "Active SOS Monitor", path: "/sos" },
    { label: "Cyber Reports Desk", path: "/complaints" }
  ];

  return <aside className="admin-sidebar"></aside>;
}
