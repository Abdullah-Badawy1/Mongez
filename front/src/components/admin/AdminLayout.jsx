import React, { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Sidebar from './Sidebar';
import Topbar from './Topbar';
import '../../styles/admin.css';

const AdminLayout = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { i18n } = useTranslation();
  const isRtl = i18n.language === 'ar';

  return (
    <div className="admin-layout d-flex" dir={isRtl ? 'rtl' : 'ltr'}>
      <div className={`admin-sidebar ${sidebarOpen ? 'show' : ''}`}>
        <Sidebar isRtl={isRtl} />
      </div>

      <div className="admin-main flex-grow-1">
        <Topbar toggleSidebar={() => setSidebarOpen(!sidebarOpen)} />

        <div className="admin-content p-4">
          <Outlet />
        </div>
      </div>

      {sidebarOpen && (
        <div
          className="sidebar-overlay d-lg-none"
          onClick={() => setSidebarOpen(false)}
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0,0,0,0.5)',
            zIndex: 1035,
          }}
        />
      )}
    </div>
  );
};

export default AdminLayout;
