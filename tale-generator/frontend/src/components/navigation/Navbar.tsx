import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import type { User } from '@supabase/supabase-js';
import { Bars3Icon, XMarkIcon } from '@heroicons/react/24/outline';

interface NavbarProps {
  user?: User | null;
  onSignOut?: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ user, onSignOut }) => {
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const userName = user?.user_metadata?.name || user?.email?.split('@')[0] || 'User';

  const handleSignOut = () => {
    onSignOut?.();
  };

  const navLinks = [
    { name: 'Dashboard', href: '/' },
    { name: 'Children', href: '/children' },
    { name: 'Heroes', href: '/heroes' },
    { name: 'Stories', href: '/stories' },
    { name: 'Generate', href: '/stories/generate' },
    { name: 'Subscription', href: '/subscription' },
  ];

  const isActive = (href: string) => {
    if (href === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(href);
  };

  return (
    <nav className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-neutral-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center space-x-2 group">
            <span className="text-xl font-semibold text-neutral-900 group-hover:text-primary-600 transition-colors">
              Tale Generator
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex md:items-center md:space-x-1">
            {navLinks.map((link) => (
              <Link
                key={link.name}
                to={link.href}
                className={`px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 ${
                  isActive(link.href)
                    ? 'text-primary-600 bg-primary-50'
                    : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50'
                }`}
              >
                {link.name}
              </Link>
            ))}
          </div>

          {/* User Menu */}
          <div className="hidden md:flex md:items-center md:space-x-4">
            <span className="text-sm text-neutral-600">{userName}</span>
            <button
              onClick={handleSignOut}
              className="px-4 py-2 text-sm font-medium text-neutral-700 hover:text-neutral-900 hover:bg-neutral-50 rounded-lg transition-colors"
            >
              Sign Out
            </button>
          </div>

          {/* Mobile menu button */}
          <button
            type="button"
            className="md:hidden p-2 rounded-lg text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50 transition-colors"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle menu"
          >
            {mobileMenuOpen ? (
              <XMarkIcon className="h-6 w-6" />
            ) : (
              <Bars3Icon className="h-6 w-6" />
            )}
          </button>
        </div>
      </div>

      {/* Mobile menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-neutral-200 bg-white">
          <div className="px-4 pt-2 pb-3 space-y-1">
            {navLinks.map((link) => (
              <Link
                key={link.name}
                to={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className={`block px-3 py-2 rounded-lg text-base font-medium transition-colors ${
                  isActive(link.href)
                    ? 'text-primary-600 bg-primary-50'
                    : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50'
                }`}
              >
                {link.name}
              </Link>
            ))}
            <div className="pt-4 pb-2 border-t border-neutral-200">
              <div className="px-3 py-2 text-sm text-neutral-600">{userName}</div>
              <button
                onClick={() => {
                  setMobileMenuOpen(false);
                  handleSignOut();
                }}
                className="w-full text-left px-3 py-2 rounded-lg text-base font-medium text-neutral-700 hover:text-neutral-900 hover:bg-neutral-50 transition-colors"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
};
