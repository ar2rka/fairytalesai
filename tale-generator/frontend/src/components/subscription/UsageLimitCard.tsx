import React from 'react';

interface UsageLimitCardProps {
  title: string;
  used: number;
  limit: number | null;
  unit: string;
  icon: React.ReactNode;
  warningThreshold?: number; // Percentage at which to show warning
}

export const UsageLimitCard: React.FC<UsageLimitCardProps> = ({
  title,
  used,
  limit,
  unit,
  icon: _icon, // Kept for backward compatibility but not used
  warningThreshold = 80
}) => {
  const getProgressPercentage = () => {
    if (limit === null) return 0; // Unlimited
    return Math.min((used / limit) * 100, 100);
  };

  const getProgressColor = () => {
    if (limit === null) return 'bg-green-500';
    const percentage = getProgressPercentage();
    if (percentage >= 100) return 'bg-red-500';
    if (percentage >= warningThreshold) return 'bg-yellow-500';
    return 'bg-green-500';
  };

  const getLimitText = () => {
    if (limit === null) return 'Unlimited';
    return `${used} / ${limit} ${unit}`;
  };

  const getRemainingText = () => {
    if (limit === null) return '';
    const remaining = Math.max(0, limit - used);
    return `${remaining} ${unit} remaining`;
  };

  return (
    <div className="bg-white rounded-lg shadow p-6 border border-gray-200">
      <div className="mb-4">
        {/* icon prop accepted but not rendered for backward compatibility */}
        <div>
          <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
          <p className="text-sm text-gray-500">{getLimitText()}</p>
        </div>
      </div>

      {limit !== null && (
        <>
          <div className="w-full bg-gray-200 rounded-full h-2.5 mb-2">
            <div
              className={`h-2.5 rounded-full ${getProgressColor()} transition-all duration-300`}
              style={{ width: `${getProgressPercentage()}%` }}
            />
          </div>
          <p className="text-xs text-gray-600">{getRemainingText()}</p>
        </>
      )}

      {limit === null && (
        <div className="text-green-600 text-sm font-medium">
          <span>Unlimited</span>
        </div>
      )}
    </div>
  );
};
