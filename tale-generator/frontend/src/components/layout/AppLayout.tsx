import React from 'react';
import { Sidebar } from '../navigation/Sidebar';
import type { User } from '@supabase/supabase-js';

interface AppLayoutProps {
  children: React.ReactNode;
  user?: User | null;
  onSignOut?: () => void;
}

export const AppLayout: React.FC<AppLayoutProps> = ({ children, user, onSignOut }) => {
  return (
    <div className="min-h-screen bg-[#F5F5F5] flex">
      <Sidebar user={user} onSignOut={onSignOut} />
      <main className="flex-1 ml-64 min-h-screen">
        {children}
      </main>
    </div>
  );
};








