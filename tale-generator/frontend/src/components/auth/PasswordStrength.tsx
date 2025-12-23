import React from 'react';
import { getPasswordStrength } from '../../utils/validation';

interface PasswordStrengthProps {
  password: string;
}

export const PasswordStrength: React.FC<PasswordStrengthProps> = ({ password }) => {
  if (!password) return null;

  const strength = getPasswordStrength(password);

  const getColor = () => {
    if (strength < 40) return 'bg-red-500';
    if (strength < 70) return 'bg-yellow-500';
    return 'bg-green-500';
  };

  const getLabel = () => {
    if (strength < 40) return 'Weak';
    if (strength < 70) return 'Medium';
    return 'Strong';
  };

  return (
    <div className="mt-2">
      <div className="flex items-center justify-between mb-1">
        <span className="text-sm text-gray-600">Password Strength:</span>
        <span className={`text-sm font-medium ${strength < 40 ? 'text-red-600' : strength < 70 ? 'text-yellow-600' : 'text-green-600'}`}>
          {getLabel()}
        </span>
      </div>
      <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
        <div
          className={`h-full ${getColor()} transition-all duration-300`}
          style={{ width: `${strength}%` }}
        />
      </div>
    </div>
  );
};
