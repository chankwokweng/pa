export type HabitType = 'boolean' | 'numeric' | 'timer';
export type TimeOfDay = 'morning' | 'afternoon' | 'evening' | 'anytime';

export interface Habit {
  id: string;
  name: string;
  description: string;
  category: string;
  type: HabitType;
  timeOfDay: TimeOfDay;
  targetValue: number; // e.g. 8 for glasses, 20 for minutes, 1 for boolean
  targetUnit: string;  // e.g. 'glasses', 'Pages', 'Mins'
  createdAt: string;
  color: string;       // e.g. 'indigo', 'rose', 'emerald'
  icon: string;        // e.g. 'Activity', 'BookOpen', 'Brain'
  isArchived: boolean;
}

export interface HabitLog {
  id: string;
  habitId: string;
  date: string;        // YYYY-MM-DD
  value: number;       // Current progress made towards goal
  targetValue: number; // The goal at that time
  isCompleted: boolean;
}

export interface CategorySpec {
  id: string;
  name: string;
  icon: string;
  color: string;
  bgColor: string;
  textColor: string;
  borderColor: string;
}

export interface Badge {
  id: string;
  title: string;
  description: string;
  icon: string;
  category: 'streaks' | 'total' | 'consistency' | 'category';
  unlockedAt?: string;
  requirementText: string;
}

export interface AppSettings {
  userName: string;
  avatarSeed: string;
  showQuote: boolean;
  themeColor: string;
  notificationsEnabled: boolean;
}
