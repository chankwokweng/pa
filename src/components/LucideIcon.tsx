import React from 'react';
import * as Icons from 'lucide-react';

interface LucideIconProps extends React.ComponentProps<'svg'> {
  name: string;
  size?: number | string;
  className?: string;
  style?: React.CSSProperties;
}

export default function LucideIcon({ name, size = 20, className = '', style, ...props }: LucideIconProps) {
  // Safe lookup with fallback
  const IconComponent = (Icons as any)[name] || Icons.HelpCircle;
  return <IconComponent size={size} className={className} style={style} {...props} />;
}
