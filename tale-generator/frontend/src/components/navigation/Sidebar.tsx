import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import type { User } from '@supabase/supabase-js';
import {
  HomeIcon,
  UserGroupIcon,
  SparklesIcon,
  BookOpenIcon,
  CreditCardIcon,
  XMarkIcon,
  ChevronDownIcon,
} from '@heroicons/react/24/outline';

interface SidebarProps {
  user?: User | null;
  onSignOut?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ user, onSignOut }) => {
  const location = useLocation();
  const [showUserMenu, setShowUserMenu] = useState(false);

  const userName = user?.user_metadata?.name || user?.email?.split('@')[0] || 'User';
  const userInitial = userName.charAt(0).toUpperCase();

  const isActive = (href: string) => {
    if (href === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(href);
  };

  const navLinks = [
    { name: 'Dashboard', href: '/', icon: HomeIcon },
    { name: 'Children', href: '/children', icon: UserGroupIcon },
    { name: 'Heroes', href: '/heroes', icon: SparklesIcon },
    { name: 'Stories', href: '/stories', icon: BookOpenIcon },
    { name: 'Generate', href: '/stories/generate', icon: SparklesIcon },
    { name: 'Subscription', href: '/subscription', icon: CreditCardIcon },
  ];

  return (
    <div className="fixed left-0 top-0 h-full w-64 bg-white border-r border-neutral-200 flex flex-col z-40">
      {/* Logo/Branding */}
      <div className="px-6 py-5 border-b border-neutral-200">
        <Link to="/" className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center">
            <SparklesIcon className="h-5 w-5 text-white" />
          </div>
          <span className="text-lg font-semibold text-neutral-900">Tale Generator</span>
        </Link>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
        {navLinks.map((link) => {
          const Icon = link.icon;
          const active = isActive(link.href);
          return (
            <Link
              key={link.name}
              to={link.href}
              className={`flex items-center space-x-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 ${
                active
                  ? 'bg-neutral-100 text-neutral-900'
                  : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50'
              }`}
            >
              <Icon className={`h-5 w-5 ${active ? 'text-neutral-900' : 'text-neutral-500'}`} />
              <span>{link.name}</span>
            </Link>
          );
        })}
      </nav>

      {/* Notifications/Alert Section */}
      <div className="px-4 py-3 border-t border-neutral-200">
        <div className="bg-neutral-800 rounded-lg px-3 py-2.5 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className="w-5 h-5 rounded-full bg-amber-500 flex items-center justify-center">
              <span className="text-xs text-white">!</span>
            </div>
            <span className="text-xs text-white font-medium">Low credits</span>
          </div>
          <button className="text-neutral-400 hover:text-white">
            <XMarkIcon className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* User Profile */}
      <div className="px-4 py-4 border-t border-neutral-200">
        <div className="relative">
          <button
            onClick={() => setShowUserMenu(!showUserMenu)}
            className="w-full flex items-center space-x-3 px-3 py-2 rounded-lg hover:bg-neutral-50 transition-colors"
          >
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center flex-shrink-0">
              <span className="text-white text-sm font-semibold">{userInitial}</span>
            </div>
            <div className="flex-1 text-left min-w-0">
              <p className="text-sm font-medium text-neutral-900 truncate">{userName}</p>
              <p className="text-xs text-neutral-500 truncate">My Workspace</p>
            </div>
            <ChevronDownIcon className={`h-4 w-4 text-neutral-400 transition-transform ${showUserMenu ? 'rotate-180' : ''}`} />
          </button>

          {/* User Menu Dropdown */}
          {showUserMenu && (
            <div className="absolute bottom-full left-0 right-0 mb-2 bg-white border border-neutral-200 rounded-lg shadow-lg py-1">
              <button
                onClick={() => {
                  setShowUserMenu(false);
                  onSignOut?.();
                }}
                className="w-full text-left px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50 transition-colors"
              >
                Sign Out
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};








