import React from 'react';
import { XMarkIcon, CheckCircleIcon, ExclamationTriangleIcon, InformationCircleIcon } from '@heroicons/react/24/outline';

interface AlertProps {
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  title?: string;
  onClose?: () => void;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export const Alert: React.FC<AlertProps> = ({ type, message, title, onClose, action }) => {
  const typeConfig = {
    success: {
      containerClasses: 'bg-green-50 border-green-200 text-green-900',
      icon: CheckCircleIcon,
      iconColor: 'text-green-600',
    },
    error: {
      containerClasses: 'bg-red-50 border-red-200 text-red-900',
      icon: ExclamationTriangleIcon,
      iconColor: 'text-red-600',
    },
    warning: {
      containerClasses: 'bg-amber-50 border-amber-200 text-amber-900',
      icon: ExclamationTriangleIcon,
      iconColor: 'text-amber-600',
    },
    info: {
      containerClasses: 'bg-blue-50 border-blue-200 text-blue-900',
      icon: InformationCircleIcon,
      iconColor: 'text-blue-600',
    },
  };

  const config = typeConfig[type];
  const Icon = config.icon;

  return (
    <div className={`border rounded-lg p-4 shadow-soft ${config.containerClasses} animate-fade-in`}>
      <div className="flex items-start">
        <Icon className={`h-5 w-5 ${config.iconColor} flex-shrink-0 mt-0.5`} />
        <div className="ml-3 flex-1">
          {title && <h3 className="font-semibold text-sm mb-1">{title}</h3>}
          <p className="text-sm">{message}</p>
          {action && (
            <button
              onClick={action.onClick}
              className="mt-2 text-sm font-medium underline hover:no-underline focus:outline-none"
            >
              {action.label}
            </button>
          )}
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="ml-4 flex-shrink-0 text-neutral-400 hover:text-neutral-600 focus:outline-none transition-colors"
            aria-label="Close alert"
          >
            <XMarkIcon className="h-5 w-5" />
          </button>
        )}
      </div>
    </div>
  );
};
