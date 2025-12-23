import React, { forwardRef } from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  variant?: 'standard' | 'filled' | 'outlined';
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, leftIcon, rightIcon, variant = 'outlined', className = '', ...props }, ref) => {

    const variantClasses = {
      standard: 'border-b-2 border-neutral-300 focus:border-primary-500 rounded-none px-0 bg-transparent',
      filled: 'bg-neutral-50 border-2 border-transparent focus:border-primary-500 focus:bg-white',
      outlined: `border ${error ? 'border-red-300' : 'border-neutral-300'} focus:border-primary-500 focus:ring-1 focus:ring-primary-500 bg-white`,
    };

    return (
      <div className="w-full">
        {label && (
          <label className="block text-sm font-medium text-neutral-700 mb-1.5">
            {label}
            {props.required && <span className="text-red-500 ml-1">*</span>}
          </label>
        )}
        <div className="relative">
          {leftIcon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400">
              {leftIcon}
            </div>
          )}
          <input
            ref={ref}
            onChange={props.onChange}
            className={`w-full py-2.5 ${leftIcon ? 'pl-10' : 'pl-3'} ${rightIcon ? 'pr-10' : 'pr-3'} rounded-lg transition-all duration-200 focus:outline-none disabled:bg-neutral-50 disabled:cursor-not-allowed text-neutral-900 placeholder-neutral-400 ${variantClasses[variant]} ${className}`}
            {...props}
          />
          {rightIcon && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400">
              {rightIcon}
            </div>
          )}
        </div>
        {error && (
          <p className="mt-1.5 text-sm text-red-600">
            {error}
          </p>
        )}
        {helperText && !error && (
          <p className="mt-1.5 text-sm text-neutral-500">{helperText}</p>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';
