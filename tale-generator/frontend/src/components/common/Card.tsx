import React from 'react';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
  variant?: 'default' | 'elevated' | 'outlined' | 'gradient';
  hover?: boolean;
  clickable?: boolean;
  onClick?: () => void;
  badge?: {
    text: string;
    color?: 'primary' | 'secondary' | 'accent' | 'success' | 'warning' | 'error';
  };
}

export const Card: React.FC<CardProps> = ({
  children,
  className = '',
  style,
  variant = 'default',
  hover = false,
  clickable = false,
  onClick,
  badge,
}) => {
  const baseClasses = 'rounded-xl transition-all duration-200';

  const variantClasses = {
    default: 'bg-white border border-neutral-200 shadow-soft',
    elevated: 'bg-white shadow-soft-md border border-neutral-200',
    outlined: 'bg-white border-2 border-neutral-200',
    gradient: 'bg-gradient-to-br from-secondary-50 to-accent-50 border border-neutral-200 shadow-soft',
  };

  const hoverClasses = hover || clickable
    ? 'hover:shadow-soft-lg hover:-translate-y-0.5 cursor-pointer'
    : '';

  const clickableClasses = clickable || onClick ? 'cursor-pointer' : '';

  const badgeColors = {
    primary: 'bg-primary-100 text-primary-800 border-primary-300',
    secondary: 'bg-secondary-100 text-secondary-800 border-secondary-300',
    accent: 'bg-accent-100 text-accent-800 border-accent-300',
    success: 'bg-green-50 text-green-700 border-green-200',
    warning: 'bg-amber-50 text-amber-700 border-amber-200',
    error: 'bg-red-50 text-red-700 border-red-200',
  };

  return (
    <div
      className={`${baseClasses} ${variantClasses[variant]} ${hoverClasses} ${clickableClasses} ${className} relative overflow-hidden`}
      style={style}
      onClick={onClick}
      role={clickable || onClick ? 'button' : undefined}
      tabIndex={clickable || onClick ? 0 : undefined}
    >
      {badge && (
        <div className="absolute top-3 right-3 z-10">
          <span className={`px-2.5 py-1 text-xs font-semibold rounded-full border ${badgeColors[badge.color || 'primary']}`}>
            {badge.text}
          </span>
        </div>
      )}
      {children}
    </div>
  );
};

interface CardHeaderProps {
  children: React.ReactNode;
  className?: string;
  action?: React.ReactNode;
}

export const CardHeader: React.FC<CardHeaderProps> = ({ children, className = '', action }) => {
  return (
    <div className={`px-6 py-4 border-b border-neutral-100 flex items-center justify-between ${className}`}>
      <div className="flex-1">{children}</div>
      {action && <div className="flex-shrink-0 ml-4">{action}</div>}
    </div>
  );
};

interface CardBodyProps {
  children: React.ReactNode;
  className?: string;
}

export const CardBody: React.FC<CardBodyProps> = ({ children, className = '' }) => {
  return <div className={`px-6 py-4 ${className}`}>{children}</div>;
};

interface CardFooterProps {
  children: React.ReactNode;
  className?: string;
}

export const CardFooter: React.FC<CardFooterProps> = ({ children, className = '' }) => {
  return (
    <div className={`px-6 py-4 border-t border-neutral-100 bg-neutral-50/50 ${className}`}>
      {children}
    </div>
  );
};
