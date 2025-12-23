import React from 'react';

interface ContainerProps {
  children: React.ReactNode;
  className?: string;
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
}

export const Container: React.FC<ContainerProps> = ({
  children,
  className = '',
  size = 'lg',
}) => {
  const sizeClasses = {
    sm: 'max-w-2xl',
    md: 'max-w-4xl',
    lg: 'max-w-6xl',
    xl: 'max-w-7xl',
    full: 'max-w-full',
  };

  return (
    <div className={`mx-auto px-4 sm:px-6 lg:px-8 ${sizeClasses[size]} ${className}`}>
      {children}
    </div>
  );
};

interface GridProps {
  children: React.ReactNode;
  className?: string;
  cols?: 1 | 2 | 3 | 4 | 6;
  gap?: 2 | 4 | 6 | 8;
}

export const Grid: React.FC<GridProps> = ({
  children,
  className = '',
  cols = 3,
  gap = 6,
}) => {
  const colClasses = {
    1: 'grid-cols-1',
    2: 'grid-cols-1 md:grid-cols-2',
    3: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3',
    4: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-4',
    6: 'grid-cols-2 md:grid-cols-3 lg:grid-cols-6',
  };

  const gapClasses = {
    2: 'gap-2',
    4: 'gap-4',
    6: 'gap-6',
    8: 'gap-8',
  };

  return (
    <div className={`grid ${colClasses[cols]} ${gapClasses[gap]} ${className}`}>
      {children}
    </div>
  );
};

interface StackProps {
  children: React.ReactNode;
  className?: string;
  direction?: 'vertical' | 'horizontal';
  spacing?: 2 | 4 | 6 | 8;
  align?: 'start' | 'center' | 'end' | 'stretch';
}

export const Stack: React.FC<StackProps> = ({
  children,
  className = '',
  direction = 'vertical',
  spacing = 4,
  align = 'stretch',
}) => {
  const directionClasses = {
    vertical: 'flex-col',
    horizontal: 'flex-row',
  };

  const spacingClasses = {
    vertical: {
      2: 'space-y-2',
      4: 'space-y-4',
      6: 'space-y-6',
      8: 'space-y-8',
    },
    horizontal: {
      2: 'space-x-2',
      4: 'space-x-4',
      6: 'space-x-6',
      8: 'space-x-8',
    },
  };

  const alignClasses = {
    start: 'items-start',
    center: 'items-center',
    end: 'items-end',
    stretch: 'items-stretch',
  };

  return (
    <div
      className={`flex ${directionClasses[direction]} ${spacingClasses[direction][spacing]} ${alignClasses[align]} ${className}`}
    >
      {children}
    </div>
  );
};
