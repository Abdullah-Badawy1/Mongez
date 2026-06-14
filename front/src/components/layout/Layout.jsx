import React from 'react';
import Header from './Header';
import ChatWidget from '../common/ChatWidget'; // اضبط المسار حسب هيكل مشروعك
import { Outlet } from 'react-router-dom';

function Layout() {
  return (
    <div className="layout">
      <Header />
      <main className="flex-grow-1">
        <Outlet />
      </main>
      <ChatWidget />
    </div>
  );
}

export default Layout;