import React from 'react';

interface SubscriptionBadgeProps {
  plan: 'free' | 'starter' | 'normal' | 'premium';
  className?: string;
}

export const SubscriptionBadge: React.FC<SubscriptionBadgeProps> = ({ plan, className = '' }) => {
  const getBadgeStyles = () => {
    switch (plan) {
      case 'premium':
        return 'bg-gradient-to-r from-purple-600 to-pink-600 text-white';
      case 'normal':
        return 'bg-gradient-to-r from-blue-600 to-cyan-600 text-white';
      case 'starter':
        return 'bg-gradient-to-r from-green-600 to-teal-600 text-white';
      case 'free':
      default:
        return 'bg-gray-200 text-gray-700';
    }
  };

  const getPlanLabel = () => {
    return plan.charAt(0).toUpperCase() + plan.slice(1);
  };

  return (
    <span
      className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold ${getBadgeStyles()} ${className}`}
    >
      {getPlanLabel()}
    </span>
  );
};
