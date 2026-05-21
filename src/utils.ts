import { Habit, HabitLog, CategorySpec, Badge } from './types';

// Standard colors with Tailwind mappings
export const CATEGORY_SPECS: Record<string, CategorySpec> = {
  health: {
    id: 'health',
    name: 'Body & Health',
    icon: 'Flame',
    color: 'emerald',
    bgColor: 'bg-emerald-50 dark:bg-emerald-950/20',
    textColor: 'text-emerald-600 dark:text-emerald-400',
    borderColor: 'border-emerald-100 dark:border-emerald-900/30'
  },
  mind: {
    id: 'mind',
    name: 'Mind & Focus',
    icon: 'Brain',
    color: 'violet',
    bgColor: 'bg-violet-50 dark:bg-violet-950/20',
    textColor: 'text-violet-600 dark:text-violet-400',
    borderColor: 'border-violet-100 dark:border-violet-900/30'
  },
  learning: {
    id: 'learning',
    name: 'Growth & Work',
    icon: 'BookOpen',
    color: 'amber',
    bgColor: 'bg-amber-50 dark:bg-amber-950/20',
    textColor: 'text-amber-600 dark:text-amber-400',
    borderColor: 'border-amber-100 dark:border-amber-900/30'
  },
  creativity: {
    id: 'creativity',
    name: 'Creativity',
    icon: 'Sparkles',
    color: 'pink',
    bgColor: 'bg-pink-50 dark:bg-pink-950/20',
    textColor: 'text-pink-600 dark:text-pink-400',
    borderColor: 'border-pink-100 dark:border-pink-900/30'
  },
  finance: {
    id: 'finance',
    name: 'Financials',
    icon: 'Coins',
    color: 'cyan',
    bgColor: 'bg-cyan-50 dark:bg-cyan-950/20',
    textColor: 'text-cyan-600 dark:text-cyan-400',
    borderColor: 'border-cyan-100 dark:border-cyan-900/30'
  }
};

export const COLOR_OPTIONS = [
  { id: 'emerald', name: 'Emerald Green', bg: 'bg-emerald-500', border: 'border-emerald-500', text: 'text-emerald-500' },
  { id: 'violet', name: 'Violet Purple', bg: 'bg-violet-500', border: 'border-violet-500', text: 'text-violet-500' },
  { id: 'amber', name: 'Amber Gold', bg: 'bg-amber-500', border: 'border-amber-500', text: 'text-amber-500' },
  { id: 'pink', name: 'Hot Pink', bg: 'bg-pink-500', border: 'border-pink-500', text: 'text-pink-500' },
  { id: 'cyan', name: 'Electric Cyan', bg: 'bg-cyan-500', border: 'border-cyan-500', text: 'text-cyan-500' },
  { id: 'rose', name: 'Rose Red', bg: 'bg-rose-500', border: 'border-rose-500', text: 'text-rose-500' },
  { id: 'indigo', name: 'Indigo Blue', bg: 'bg-indigo-500', border: 'border-indigo-500', text: 'text-indigo-500' },
];

export const ICON_OPTIONS = [
  'Activity', 'BookOpen', 'Brain', 'Flame', 'Sparkles', 'Coins', 'GlassWater', 'Heart', 
  'Compass', 'Dumbbell', 'Gamepad2', 'CheckCircle2', 'Moon', 'Coffee', 'Music', 'Smile'
];

export const INITIAL_HABITS: Habit[] = [
  {
    id: 'habit-1',
    name: 'Hydrate Consistently',
    description: 'Drink 8 glasses of water throughout the day to stay active and fresh.',
    category: 'health',
    type: 'numeric',
    timeOfDay: 'anytime',
    targetValue: 8,
    targetUnit: 'glasses',
    createdAt: new Date().toISOString(),
    color: 'cyan',
    icon: 'GlassWater',
    isArchived: false,
  },
  {
    id: 'habit-2',
    name: 'Daily Mindfulness Meditation',
    description: 'Quiet the mind and focus on deliberate breathing.',
    category: 'mind',
    type: 'timer',
    timeOfDay: 'morning',
    targetValue: 600, // 10 minutes in seconds
    targetUnit: 'secs',
    createdAt: new Date().toISOString(),
    color: 'violet',
    icon: 'Brain',
    isArchived: false,
  },
  {
    id: 'habit-3',
    name: 'Read Inspiring Literature',
    description: 'Read 20 pages of self-development or fiction books.',
    category: 'learning',
    type: 'numeric',
    timeOfDay: 'evening',
    targetValue: 20,
    targetUnit: 'pages',
    createdAt: new Date().toISOString(),
    color: 'amber',
    icon: 'BookOpen',
    isArchived: false,
  },
  {
    id: 'habit-4',
    name: 'Swork & Stretch Routine',
    description: 'Do a 15-minute mobility routine to preserve posture.',
    category: 'health',
    type: 'boolean',
    timeOfDay: 'morning',
    targetValue: 1,
    targetUnit: 'times',
    createdAt: new Date().toISOString(),
    color: 'emerald',
    icon: 'Dumbbell',
    isArchived: false,
  }
];

export const DEFAULT_BADGES: Badge[] = [
  {
    id: 'badge-first-step',
    title: 'First Step',
    description: 'Complete your first habit entry!',
    icon: 'CheckCircle2',
    category: 'total',
    requirementText: 'Log any habit as complete once'
  },
  {
    id: 'badge-consistency-3',
    title: 'Habit Starter',
    description: 'Achieve a 3-day completion streak on any habit.',
    icon: 'Flame',
    category: 'streaks',
    requirementText: 'Active streak of 3 days on 1+ habits'
  },
  {
    id: 'badge-consistency-7',
    title: '7-Day Warrior',
    description: 'Maintain a 7-day completion streak on any habit!',
    icon: 'Sparkles',
    category: 'streaks',
    requirementText: 'Active streak of 7 days on 1+ habits'
  },
  {
    id: 'badge-centurion',
    title: 'Centurion Tracker',
    description: 'Log a total of 25 completed habits across the tracker.',
    icon: 'Coins',
    category: 'total',
    requirementText: 'Accumulate 25 total logs completed'
  },
  {
    id: 'badge-mindful-master',
    title: 'Zen Master',
    description: 'Complete 5 counts of mind/meditation habits.',
    icon: 'Brain',
    category: 'category',
    requirementText: 'Complete Mind habits 5 times'
  }
];

export const MOTIVATIONAL_QUOTES = [
  { text: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.", author: "Aristotle" },
  { text: "It is easier to prevent bad habits than to break them.", author: "Benjamin Franklin" },
  { text: "Your habits will determine your future.", author: "Jack Canfield" },
  { text: "Motivation is what gets you started. Habit is what keeps you going.", author: "Jim Ryun" },
  { text: "Small daily improvements over time lead to stunning results.", author: "Robin Sharma" },
  { text: "All big things come from small beginnings. The seed of every habit is a single, tiny decision.", author: "James Clear, Atomic Habits" },
  { text: "You do not rise to the level of your goals. You fall to the level of your systems.", author: "James Clear, Atomic Habits" }
];

/**
 * Gets a YYYY-MM-DD date string based on a Date object, keeping in local time.
 */
export function getLocalDateString(date = new Date()): string {
  const offset = date.getTimezoneOffset();
  const adjusted = new Date(date.getTime() - offset * 60 * 1000);
  return adjusted.toISOString().split('T')[0];
}

/**
 * Calculates historical date range (e.g. last N days including today).
 */
export function getLastNDays(n: number): string[] {
  const dates: string[] = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    dates.push(getLocalDateString(d));
  }
  return dates;
}

/**
 * Get date object from YYYY-MM-DD local format
 */
export function parseLocalDate(dateStr: string): Date {
  const parts = dateStr.split('-');
  return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
}

/**
 * Format seconds to MM:SS or HH:MM:SS
 */
export function formatDuration(seconds: number): string {
  if (isNaN(seconds) || seconds < 0) return '00:00';
  const hrs = Math.floor(seconds / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;

  const pad = (num: number) => num.toString().padStart(2, '0');

  if (hrs > 0) {
    return `${hrs}:${pad(mins)}:${pad(secs)}`;
  }
  return `${pad(mins)}:${pad(secs)}`;
}

/**
 * Calculate the current streak and longest streak of completions for a single habit
 */
export function calculateStreak(habitId: string, logs: HabitLog[]): { current: number; longest: number } {
  // Filter and sort completed logs for this habit descending (newest first)
  const completedDates = Array.from(
    new Set(
      logs
        .filter(l => l.habitId === habitId && l.isCompleted)
        .map(l => l.date)
    )
  ).sort((a, b) => b.localeCompare(a)); // sorted Z-A / Newest-Oldest

  if (completedDates.length === 0) {
    return { current: 0, longest: 0 };
  }

  // Calculate current streak
  let currentStreak = 0;
  const todayStr = getLocalDateString(new Date());
  
  const tempDate = new Date();
  tempDate.setDate(tempDate.getDate() - 1);
  const yesterdayStr = getLocalDateString(tempDate);

  // If the habit is completed today or yesterday, the current streak is active
  const hasCompletedToday = completedDates.includes(todayStr);
  const hasCompletedYesterday = completedDates.includes(yesterdayStr);

  if (hasCompletedToday || hasCompletedYesterday) {
    let checkDateString = hasCompletedToday ? todayStr : yesterdayStr;
    let keepChecking = true;
    let checkDate = parseLocalDate(checkDateString);

    while (keepChecking) {
      const formattedCheck = getLocalDateString(checkDate);
      if (completedDates.includes(formattedCheck)) {
        currentStreak++;
        // Move to previous day
        checkDate.setDate(checkDate.getDate() - 1);
      } else {
        keepChecking = false;
      }
    }
  }

  // Calculate longest streak historically
  let longestStreak = 0;
  let runningStreak = 0;
  
  // Sort oldest to newest to find historic continuous bands
  const oldestToNewest = [...completedDates].sort((a,b) => a.localeCompare(b));
  
  if (oldestToNewest.length > 0) {
    longestStreak = 1;
    runningStreak = 1;
    
    for (let i = 1; i < oldestToNewest.length; i++) {
      const prevDate = parseLocalDate(oldestToNewest[i - 1]);
      const currDate = parseLocalDate(oldestToNewest[i]);
      
      // Check if dates are consecutive days
      const diffTime = Math.abs(currDate.getTime() - prevDate.getTime());
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      
      if (diffDays === 1) {
        runningStreak++;
      } else if (diffDays > 1) {
        runningStreak = 1; // broken streak, start over
      }
      
      if (runningStreak > longestStreak) {
        longestStreak = runningStreak;
      }
    }
  }
  
  // If current streak is somehow greater (safety check)
  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  return { current: currentStreak, longest: longestStreak };
}

/**
 * Filter logs to find completed habits count per category
 */
export function getCompletedHabitCountByCategory(logs: HabitLog[], habits: Habit[], categoryId: string): number {
  const targetHabitIds = habits.filter(h => h.category === categoryId).map(h => h.id);
  return logs.filter(l => targetHabitIds.includes(l.habitId) && l.isCompleted).length;
}

/**
 * Check badge unlock conditions and returns unlocked list
 */
export function checkBadges(habits: Habit[], logs: HabitLog[], existingBadges: Badge[]): Badge[] {
  const totalCompleted = logs.filter(l => l.isCompleted).length;
  
  return existingBadges.map(badge => {
    if (badge.unlockedAt) return badge; // Already unlocked
    
    let unlocked = false;
    
    if (badge.id === 'badge-first-step') {
      unlocked = totalCompleted >= 1;
    } else if (badge.id === 'badge-centurion') {
      unlocked = totalCompleted >= 25;
    } else if (badge.id === 'badge-mindful-master') {
      const mindCompleted = getCompletedHabitCountByCategory(logs, habits, 'mind');
      unlocked = mindCompleted >= 5;
    } else if (badge.id === 'badge-consistency-3') {
      unlocked = habits.some(h => calculateStreak(h.id, logs).longest >= 3);
    } else if (badge.id === 'badge-consistency-7') {
      unlocked = habits.some(h => calculateStreak(h.id, logs).longest >= 7);
    }
    
    if (unlocked) {
      return {
        ...badge,
        unlockedAt: new Date().toISOString()
      };
    }
    
    return badge;
  });
}
