import React from 'react';

interface CircularProgressProps {
  percentage: number;
  size?: number;
  strokeWidth?: number;
  colorClass?: string;
  bgColorClass?: string;
  children?: React.ReactNode;
}

export default function CircularProgress({
  percentage,
  size = 120,
  strokeWidth = 10,
  colorClass = 'text-indigo-600 dark:text-indigo-400',
  bgColorClass = 'text-gray-150 dark:text-gray-800',
  children
}: CircularProgressProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  // Ensure we clamp percentage between 0 and 100
  const cleanPercentage = Math.min(Math.max(percentage, 0), 100);
  const strokeDashoffset = circumference - (cleanPercentage / 100) * circumference;

  return (
    <div className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <svg className="transform -rotate-90" width={size} height={size}>
        {/* Background circle */}
        <circle
          className={bgColorClass}
          stroke="currentColor"
          fill="transparent"
          strokeWidth={strokeWidth}
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
        {/* Foreground animated progress bar */}
        <circle
          className={`${colorClass} transition-all duration-300 ease-out`}
          stroke="currentColor"
          fill="transparent"
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          strokeLinecap="round"
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
      </svg>
      {children && (
        <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
          {children}
        </div>
      )}
    </div>
  );
}
