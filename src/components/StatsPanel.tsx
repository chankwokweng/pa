import { useMemo } from 'react';
import { Habit, HabitLog, Badge } from '../types';
import { DEFAULT_BADGES, CATEGORY_SPECS, getLastNDays, calculateStreak, parseLocalDate } from '../utils';
import LucideIcon from './LucideIcon';

interface StatsPanelProps {
  habits: Habit[];
  logs: HabitLog[];
  badges: Badge[];
}

export default function StatsPanel({ habits, logs, badges }: StatsPanelProps) {
  const activeHabits = useMemo(() => habits.filter(h => !h.isArchived), [habits]);

  // General scores
  const generalStats = useMemo(() => {
    const totalPossibleCount = activeHabits.length;
    const completedTodayCount = logs.filter(
      l => {
        const todayStr = new Date().toISOString().split('T')[0];
        return l.date === todayStr && l.isCompleted;
      }
    ).length;

    const completionRateToday = totalPossibleCount > 0 
      ? Math.round((completedTodayCount / totalPossibleCount) * 100) 
      : 0;

    // Total logs ever completed
    const allCompletedLogsCount = logs.filter(l => l.isCompleted).length;

    // Highest current streak
    let maxCurrentStreak = 0;
    let maxLongestStreak = 0;
    activeHabits.forEach(h => {
      const { current, longest } = calculateStreak(h.id, logs);
      if (current > maxCurrentStreak) maxCurrentStreak = current;
      if (longest > maxLongestStreak) maxLongestStreak = longest;
    });

    return {
      completionRateToday,
      allCompletedLogsCount,
      maxCurrentStreak,
      maxLongestStreak,
    };
  }, [activeHabits, logs]);

  // Category completion summary
  const categoryStats = useMemo(() => {
    return Object.keys(CATEGORY_SPECS).map(catId => {
      const spec = CATEGORY_SPECS[catId];
      const habitsInCat = habits.filter(h => h.category === catId && !h.isArchived);
      
      let loggedCompleted = 0;
      let totalLogs = 0;

      // Scan last 30 days to check category adherence
      const last30Days = getLastNDays(30);
      last30Days.forEach(dateStr => {
        habitsInCat.forEach(h => {
          totalLogs++;
          const foundLog = logs.find(l => l.habitId === h.id && l.date === dateStr);
          if (foundLog?.isCompleted) {
            loggedCompleted++;
          }
        });
      });

      const percentage = totalLogs > 0 ? Math.round((loggedCompleted / totalLogs) * 100) : 0;
      return {
        ...spec,
        count: habitsInCat.length,
        percentage,
        completions: loggedCompleted
      };
    });
  }, [habits, logs]);

  // Heatmap: 8 weeks = 56 days
  const heatmapDays = useMemo(() => {
    const days = getLastNDays(56); // 8 weeks
    const todayStr = new Date().toISOString().split('T')[0];
    
    return days.map(d => {
      const habitsOnThisDay = habits.filter(h => {
        // If created before or on this day, count as checkable
        return h.createdAt.split('T')[0] <= d && !h.isArchived;
      });

      const dayLogs = logs.filter(l => l.date === d);
      const completedOnThisDay = dayLogs.filter(l => {
        const matchingHabit = habitsOnThisDay.find(h => h.id === l.habitId);
        return matchingHabit && l.isCompleted;
      }).length;

      const possible = habitsOnThisDay.length;
      const ratio = possible > 0 ? completedOnThisDay / possible : 0;

      let colorLevel = 'bg-gray-100 dark:bg-gray-800/60'; // 0
      if (ratio > 0 && ratio <= 0.3) colorLevel = 'bg-emerald-100 dark:bg-emerald-950/30 text-emerald-800';
      else if (ratio > 0.3 && ratio <= 0.65) colorLevel = 'bg-emerald-300 dark:bg-emerald-800/50 text-white';
      else if (ratio > 0.65 && ratio <= 0.9) colorLevel = 'bg-emerald-500 text-white';
      else if (ratio > 0.9) colorLevel = 'bg-emerald-600 dark:bg-emerald-500 text-white shadow-xs';

      // Nice short day name
      const pDate = parseLocalDate(d);
      const label = pDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

      return {
        date: d,
        label,
        completed: completedOnThisDay,
        possible,
        ratio,
        colorLevel,
        isToday: d === todayStr
      };
    });
  }, [habits, logs]);

  return (
    <div className="space-y-6" id="stats-panel-container">
      {/* 1. Score Grid */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <div className="rounded-2xl border border-gray-150 bg-white p-4 text-center dark:border-gray-800 dark:bg-gray-900 shadow-3xs" id="stat-card-today">
          <div className="mx-auto flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-50 text-indigo-500 dark:bg-indigo-950/30 dark:text-indigo-400">
            <LucideIcon name="Activity" size={18} />
          </div>
          <span className="mt-2 block text-2xl font-bold tracking-tight text-gray-900 dark:text-gray-50 bg-linear-to-r from-indigo-500 to-indigo-600 bg-clip-text text-transparent">
            {generalStats.completionRateToday}%
          </span>
          <span className="text-3xs font-medium text-gray-400 block uppercase tracking-wide">Today Completed</span>
        </div>

        <div className="rounded-2xl border border-gray-150 bg-white p-4 text-center dark:border-gray-800 dark:bg-gray-900 shadow-3xs" id="stat-card-logs">
          <div className="mx-auto flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-50 text-emerald-500 dark:bg-emerald-950/30 dark:text-emerald-400">
            <LucideIcon name="CheckCircle2" size={18} />
          </div>
          <span className="mt-2 block text-2xl font-bold tracking-tight text-gray-900 dark:text-gray-50">
            {generalStats.allCompletedLogsCount}
          </span>
          <span className="text-3xs font-medium text-gray-400 block uppercase tracking-wide">Total Check-ins</span>
        </div>

        <div className="rounded-2xl border border-gray-150 bg-white p-4 text-center dark:border-gray-800 dark:bg-gray-900 shadow-3xs" id="stat-card-streak-cur">
          <div className="mx-auto flex h-8 w-8 items-center justify-center rounded-lg bg-amber-50 text-amber-500 dark:bg-amber-950/30 dark:text-amber-400">
            <LucideIcon name="Flame" size={18} className="animate-pulse" />
          </div>
          <span className="mt-2 block text-2xl font-bold tracking-tight text-gray-900 dark:text-gray-50">
            {generalStats.maxCurrentStreak} d
          </span>
          <span className="text-3xs font-medium text-gray-400 block uppercase tracking-wide">Power Streak</span>
        </div>

        <div className="rounded-2xl border border-gray-150 bg-white p-4 text-center dark:border-gray-800 dark:bg-gray-900 shadow-3xs" id="stat-card-streak-long">
          <div className="mx-auto flex h-8 w-8 items-center justify-center rounded-lg bg-pink-50 text-pink-500 dark:bg-pink-950/30 dark:text-pink-400">
            <LucideIcon name="Sparkles" size={18} />
          </div>
          <span className="mt-2 block text-2xl font-bold tracking-tight text-gray-900 dark:text-gray-50">
            {generalStats.maxLongestStreak} d
          </span>
          <span className="text-3xs font-medium text-gray-400 block uppercase tracking-wide">Record Streak</span>
        </div>
      </div>

      {/* 2. GitHub-Style Calender Grid Map */}
      <div className="rounded-2xl border border-gray-150 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-3xs">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">Consistency Heatmap</h3>
            <p className="text-3xs text-gray-400">Historical performance grid over the last 8 weeks</p>
          </div>
          <div className="flex items-center space-x-1.5 text-3xs text-gray-400 font-medium scale-90">
            <span>Less</span>
            <div className="h-2 w-2 rounded bg-gray-100 dark:bg-gray-800" />
            <div className="h-2 w-2 rounded bg-emerald-100 dark:bg-emerald-950/30" />
            <div className="h-2 w-2 rounded bg-emerald-300 dark:bg-emerald-800/50" />
            <div className="h-2 w-2 rounded bg-emerald-500" />
            <div className="h-2 w-2 rounded bg-emerald-600" />
            <span>More</span>
          </div>
        </div>

        {/* 56 Grid Cells */}
        <div className="grid grid-flow-col grid-rows-7 gap-1.5 justify-center overflow-x-auto pb-1" id="heatmap-grid">
          {heatmapDays.map((hd, idx) => (
            <div
              key={hd.date}
              className={`group relative h-4 w-4 rounded-sm transition-all hover:scale-120 ${hd.colorLevel} ${
                hd.isToday ? 'outline-2 outline-gray-500 outline-offset-1 ring-1 ring-offset-2 ring-transparent' : ''
              }`}
            >
              {/* Micro interactive tooltip */}
              <div className="pointer-events-none absolute bottom-6 left-1/2 z-30 w-36 -translate-x-1/2 scale-0 rounded-lg bg-gray-900 dark:bg-gray-850 p-2 text-center text-4xs leading-normal font-semibold text-white opacity-0 shadow-lg transition-all group-hover:scale-100 group-hover:opacity-100 select-none">
                <span className="font-extrabold text-xs block text-slate-200">{hd.label}</span>
                {hd.possible > 0 ? (
                  <span>Completed: {hd.completed} / {hd.possible} habits ({Math.round(hd.ratio * 100)}%)</span>
                ) : (
                  <span>No active habits yet</span>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 3. Divided Layout: Categories Adherence & Medal Trophy Room */}
      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        
        {/* Category breakdown */}
        <div className="rounded-2xl border border-gray-150 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-3xs" id="category-box">
          <div className="mb-4">
            <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">Category Dedication</h3>
            <p className="text-3xs text-gray-400">Total completion share calculated for the last 30 days</p>
          </div>

          <div className="space-y-4">
            {categoryStats.map(cat => (
              <div key={cat.id} className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center space-x-2">
                    <span className={`inline-flex items-center justify-center p-1 rounded-md ${cat.bgColor} ${cat.textColor}`}>
                      <LucideIcon name={cat.icon} size={14} />
                    </span>
                    <span className="font-semibold text-gray-750 dark:text-gray-200">{cat.name}</span>
                    <span className="text-4xs text-gray-400 font-medium">({cat.count} active)</span>
                  </div>
                  <span className="font-bold text-gray-900 dark:text-gray-150">{cat.percentage}%</span>
                </div>
                {/* Visual Segment Bar */}
                <div className="h-2 w-full overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
                  <div
                    style={{ width: `${cat.percentage}%` }}
                    className={`h-full rounded-full transition-all duration-500 ${
                      cat.color === 'emerald' ? 'bg-emerald-500' : ''
                    }${
                      cat.color === 'violet' ? 'bg-violet-500' : ''
                    }${
                      cat.color === 'amber' ? 'bg-amber-500' : ''
                    }${
                      cat.color === 'pink' ? 'bg-pink-500' : ''
                    }${
                      cat.color === 'cyan' ? 'bg-cyan-500' : ''
                    }`}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Unlocked Medals Badges Shelf */}
        <div className="rounded-2xl border border-gray-150 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-3xs" id="medals-box">
          <div className="mb-4">
            <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">Badge & Achievement Shelf</h3>
            <p className="text-3xs text-gray-400">Unlocks automatically as you crush your wellness targets</p>
          </div>

          <div className="grid grid-cols-2 gap-3 max-h-76 overflow-y-auto pr-1">
            {badges.map(b => {
              const unlocked = !!b.unlockedAt;
              return (
                <div
                  key={b.id}
                  className={`flex items-center space-x-2.5 rounded-xl border p-2.5 transition-all duration-300 ${
                    unlocked
                      ? 'border-emerald-100 bg-emerald-50/25 dark:border-emerald-900/30 dark:bg-emerald-950/10'
                      : 'border-gray-100 bg-gray-50/50 dark:border-gray-850 dark:bg-gray-900/30 opacity-75'
                  }`}
                >
                  <div
                    className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg shadow-3xs ${
                      unlocked
                        ? 'bg-emerald-500 text-white animate-pulse'
                        : 'bg-gray-200 text-gray-400 dark:bg-gray-800 dark:text-gray-500'
                    }`}
                  >
                    <LucideIcon name={b.icon} size={18} />
                  </div>
                  <div className="min-w-0">
                    <h4 className={`text-2xs font-extrabold truncate ${unlocked ? 'text-gray-850 dark:text-white' : 'text-gray-400 dark:text-gray-500'}`}>
                      {b.title}
                    </h4>
                    <span className="text-4xs text-gray-400 dark:text-gray-500 block leading-tight clamp-1 select-none font-medium truncate">
                      {unlocked ? 'Unlocked!' : b.requirementText}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

      </div>
    </div>
  );
}
