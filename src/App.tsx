/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useState, useEffect, useMemo } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Habit, HabitLog, Badge, AppSettings } from './types';
import {
  INITIAL_HABITS,
  DEFAULT_BADGES,
  MOTIVATIONAL_QUOTES,
  getLocalDateString,
  getLocalDateString as _getTodayStr,
  getLastNDays,
  calculateStreak,
  checkBadges,
  parseLocalDate
} from './utils';

// Subcomponents
import HabitCard from './components/HabitCard';
import StatsPanel from './components/StatsPanel';
import HabitFormModal from './components/HabitFormModal';
import SettingsPanel from './components/SettingsPanel';
import ConfirmDialog from './components/ConfirmDialog';
import LucideIcon from './components/LucideIcon';

export default function App() {
  // --- STATE DECLARATIONS ---
  const [habits, setHabits] = useState<Habit[]>([]);
  const [logs, setLogs] = useState<HabitLog[]>([]);
  const [badges, setBadges] = useState<Badge[]>([]);
  const [settings, setSettings] = useState<AppSettings>({
    userName: 'Aura Achiever',
    avatarSeed: 'avatar-1',
    showQuote: true,
    themeColor: 'indigo',
    notificationsEnabled: false
  });

  const [activeTab, setActiveTab] = useState<'daily' | 'habits' | 'stats' | 'settings'>('daily');
  const [selectedDate, setSelectedDate] = useState<string>(getLocalDateString(new Date()));
  const [selectedTimeOfDay, setSelectedTimeOfDay] = useState<'all' | 'morning' | 'afternoon' | 'evening'>('all');
  
  // Modals & UX State
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingHabit, setEditingHabit] = useState<Habit | null>(null);
  const [quoteIndex, setQuoteIndex] = useState(0);
  const [unlockedBadgeToast, setUnlockedBadgeToast] = useState<Badge | null>(null);

  // --- INITIAL LOADING ---
  useEffect(() => {
    // 1. Habits
    const cachedHabits = localStorage.getItem('aurahabit_habits');
    if (cachedHabits) {
      try {
        setHabits(JSON.parse(cachedHabits));
      } catch (e) {
        setHabits(INITIAL_HABITS);
      }
    } else {
      setHabits(INITIAL_HABITS);
      localStorage.setItem('aurahabit_habits', JSON.stringify(INITIAL_HABITS));
    }

    // 2. Logs
    const cachedLogs = localStorage.getItem('aurahabit_logs');
    if (cachedLogs) {
      try {
        setLogs(JSON.parse(cachedLogs));
      } catch (e) {
        setLogs([]);
      }
    }

    // 3. Badges
    const cachedBadges = localStorage.getItem('aurahabit_badges');
    if (cachedBadges) {
      try {
        setBadges(JSON.parse(cachedBadges));
      } catch (e) {
        setBadges(DEFAULT_BADGES);
      }
    } else {
      setBadges(DEFAULT_BADGES);
      localStorage.setItem('aurahabit_badges', JSON.stringify(DEFAULT_BADGES));
    }

    // 4. Settings
    const cachedSettings = localStorage.getItem('aurahabit_settings');
    if (cachedSettings) {
      try {
        setSettings(JSON.parse(cachedSettings));
      } catch (e) {
        // use default state
      }
    }

    // Rotate Quote
    setQuoteIndex(Math.floor(Math.random() * MOTIVATIONAL_QUOTES.length));
  }, []);

  // --- SYNC ENGINE ---
  const saveHabits = (newHabits: Habit[]) => {
    setHabits(newHabits);
    localStorage.setItem('aurahabit_habits', JSON.stringify(newHabits));
  };

  const saveLogs = (newLogs: HabitLog[]) => {
    setLogs(newLogs);
    localStorage.setItem('aurahabit_logs', JSON.stringify(newLogs));
    
    // Check Badge achievements dynamically whenever a new log entry saves!
    const updatedBadges = checkBadges(habits, newLogs, badges);
    const newlyUnlocked = updatedBadges.find((b, idx) => b.unlockedAt && !badges[idx].unlockedAt);
    
    if (newlyUnlocked) {
      setUnlockedBadgeToast(newlyUnlocked);
      // Auto dismiss after 4 seconds
      setTimeout(() => {
        setUnlockedBadgeToast(null);
      }, 4000);
    }
    
    setBadges(updatedBadges);
    localStorage.setItem('aurahabit_badges', JSON.stringify(updatedBadges));
  };

  const saveSettings = (newSettings: AppSettings) => {
    setSettings(newSettings);
    localStorage.setItem('aurahabit_settings', JSON.stringify(newSettings));
  };


  // --- CALENDAR STRIP GENERATOR ---
  const calendarDays = useMemo(() => {
    const dates = getLastNDays(7); // Last 7 days to slide browse
    return dates.map(d => {
      const pDate = parseLocalDate(d);
      const isToday = d === getLocalDateString(new Date());
      const isSelected = d === selectedDate;
      const dayName = pDate.toLocaleDateString('en-US', { weekday: 'narrow' });
      const dayNum = pDate.getDate();

      // completion level for UI glow dots
      const habitsOnThisDay = habits.filter(h => h.createdAt.split('T')[0] <= d && !h.isArchived);
      const dayLogs = logs.filter(l => l.date === d);
      const completedCount = dayLogs.filter(l => {
        const matchingHabit = habitsOnThisDay.find(h => h.id === l.habitId);
        return matchingHabit && l.isCompleted;
      }).length;

      const completionRatio = habitsOnThisDay.length > 0 ? completedCount / habitsOnThisDay.length : 0;

      return {
        date: d,
        dayName,
        dayNum,
        isToday,
        isSelected,
        completionRatio
      };
    });
  }, [selectedDate, habits, logs]);


  // --- ACTIVE DISPLAY ROUTINE FILTER FILTERING ---
  const filteredHabits = useMemo(() => {
    return habits.filter(h => {
      // 1. Cannot be archived
      if (h.isArchived) return false;
      // 2. Filter by creation timestamp
      const createdDateString = h.createdAt.split('T')[0];
      if (createdDateString > selectedDate) return false;
      // 3. Filter by Time of Day
      if (selectedTimeOfDay !== 'all' && h.timeOfDay !== selectedTimeOfDay) return false;
      
      return true;
    });
  }, [habits, selectedDate, selectedTimeOfDay]);


  // --- DATA ACCESS OPERATIONS ---
  const handleUpdateProgress = (habitId: string, newValue: number) => {
    const activeHabit = habits.find(h => h.id === habitId);
    if (!activeHabit) return;

    const logIndex = logs.findIndex(l => l.habitId === habitId && l.date === selectedDate);
    const targetValue = activeHabit.targetValue;
    const isNowCompleted = newValue >= targetValue;

    let nextLogs = [...logs];

    if (logIndex >= 0) {
      // Update existing record
      nextLogs[logIndex] = {
        ...nextLogs[logIndex],
        value: newValue,
        isCompleted: isNowCompleted
      };
    } else {
      // Create fresh log detail
      const newLog: HabitLog = {
        id: `log-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
        habitId,
        date: selectedDate,
        value: newValue,
        targetValue,
        isCompleted: isNowCompleted
      };
      nextLogs.push(newLog);
    }

    saveLogs(nextLogs);
  };

  const handleCreateOrUpdateHabit = (habitInput: Omit<Habit, 'id' | 'createdAt' | 'isArchived'>) => {
    if (editingHabit) {
      // Edit mode
      const nextHabits = habits.map(h => {
        if (h.id === editingHabit.id) {
          return {
            ...h,
            ...habitInput
          };
        }
        return h;
      });
      saveHabits(nextHabits);
      setEditingHabit(null);
    } else {
      // Create mode
      const newHabit: Habit = {
        ...habitInput,
        id: `habit-${Date.now()}`,
        createdAt: new Date().toISOString(),
        isArchived: false
      };
      saveHabits([...habits, newHabit]);
    }
  };

  const [archiveHabitId, setArchiveHabitId] = useState<string | null>(null);

  const handleArchiveHabit = (habitId: string) => {
    setArchiveHabitId(habitId);
  };

  const handleConfirmArchive = () => {
    if (!archiveHabitId) return;
    const nextHabits = habits.map(h => {
      if (h.id === archiveHabitId) {
        return { ...h, isArchived: true };
      }
      return h;
    });
    saveHabits(nextHabits);
    setArchiveHabitId(null);
  };

  const handleImportDatabase = (importedHabits: Habit[], importedLogs: HabitLog[]) => {
    saveHabits(importedHabits);
    saveLogs(importedLogs);
    setActiveTab('daily');
  };

  const handleFactoryReset = () => {
    setHabits(INITIAL_HABITS);
    setLogs([]);
    setBadges(DEFAULT_BADGES);
    setSettings({
      userName: 'Aura Achiever',
      avatarSeed: 'avatar-1',
      showQuote: true,
      themeColor: 'indigo',
      notificationsEnabled: false
    });
    
    localStorage.setItem('aurahabit_habits', JSON.stringify(INITIAL_HABITS));
    localStorage.removeItem('aurahabit_logs');
    localStorage.setItem('aurahabit_badges', JSON.stringify(DEFAULT_BADGES));
    localStorage.removeItem('aurahabit_settings');
    setSelectedDate(getLocalDateString(new Date()));
    setActiveTab('daily');
  };

  const activeQuote = MOTIVATIONAL_QUOTES[quoteIndex];

  // Simple current day readable formatting for dashboard summary header
  const headerDateString = useMemo(() => {
    const pDate = parseLocalDate(selectedDate);
    return pDate.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' });
  }, [selectedDate]);

  return (
    <div className={`min-h-screen bg-slate-50 dark:bg-gray-950 text-gray-900 pb-24 md:pb-6 transition-all duration-300 dark:text-zinc-100`}>
      {/* 1. Global Navigation Top Bar */}
      <header className="sticky top-0 z-30 border-b border-gray-150 bg-white/95 py-3.5 backdrop-blur-md dark:border-gray-800 dark:bg-gray-950/90 shadow-2xs">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-4">
          <div className="flex items-center space-x-2">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-md shadow-indigo-600/20">
              <LucideIcon name="Flame" size={18} className="animate-pulse" />
            </div>
            <div>
              <span className="text-sm font-extrabold tracking-tight text-gray-900 dark:text-zinc-100">AuraHabit</span>
              <span className="ml-1 text-4xs font-bold uppercase tracking-wider text-indigo-500 bg-indigo-50 dark:bg-indigo-950/40 px-1 py-0.5 rounded border border-indigo-100 dark:border-indigo-900/30">Offline PWA</span>
            </div>
          </div>

          {/* Desktop Navigation Link buttons */}
          <nav className="hidden md:flex space-x-1 font-medium text-xs">
            {([
              { id: 'daily', name: 'Today Board', icon: 'CheckCircle2' },
              { id: 'habits', name: 'Habit Manager', icon: 'Activity' },
              { id: 'stats', name: 'Stats & Levels', icon: 'Coins' },
              { id: 'settings', name: 'Settings Options', icon: 'Sparkles' }
            ] as const).map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-2 rounded-xl px-4 py-2.5 transition ${
                  activeTab === tab.id
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-gray-500 hover:bg-gray-100 hover:text-gray-800 dark:text-gray-400 dark:hover:bg-gray-850 dark:hover:text-zinc-200'
                }`}
              >
                <LucideIcon name={tab.icon} size={15} />
                <span>{tab.name}</span>
              </button>
            ))}
          </nav>

          <div className="flex items-center space-x-3">
            <div className="text-right">
              <span className="text-3xs text-gray-400 block font-medium">Hello,</span>
              <span className="text-xs font-bold text-gray-800 dark:text-gray-150 leading-tight block">{settings.userName}</span>
            </div>
            <div className="h-8 w-8 rounded-full bg-indigo-100 border border-indigo-300 dark:border-indigo-800 dark:bg-indigo-950/60 flex items-center justify-center text-indigo-600 dark:text-indigo-400 font-extrabold text-xs">
              {settings.userName[0]?.toUpperCase() || 'A'}
            </div>
          </div>
        </div>
      </header>

      {/* 2. Main Scaffold */}
      <main className="mx-auto max-w-5xl px-4 pt-6">
        
        {/* Quote banner */}
        {settings.showQuote && activeTab === 'daily' && activeQuote && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-6 rounded-2xl border border-indigo-100 bg-linear-to-r from-indigo-50/40 to-violet-50/20 p-4 relative overflow-hidden dark:border-indigo-900/40 dark:from-indigo-950/10 dark:to-violet-950/5 shadow-2xs"
          >
            <div className="pr-6">
              <span className="text-3xs font-extrabold text-indigo-500 uppercase tracking-widest block mb-1 font-mono">ATOMIC INSIGHT</span>
              <p className="text-2xs font-medium text-gray-750 dark:text-gray-300 italic">
                "{activeQuote.text}"
              </p>
              <span className="text-4xs text-gray-400 font-bold block mt-1">— {activeQuote.author}</span>
            </div>
            <button
              onClick={() => setSettings({ ...settings, showQuote: false })}
              className="absolute top-3 right-3 text-gray-400 hover:text-gray-600 transition"
              title="Dismiss"
            >
              <LucideIcon name="Sparkles" size={12} className="rotate-45" />
            </button>
          </motion.div>
        )}

        {/* --- ROUTE VIEW RENDERERS --- */}
        <AnimatePresence mode="wait">
          {activeTab === 'daily' && (
            <motion.div
              key="daily-board"
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              transition={{ duration: 0.15 }}
              className="space-y-6"
            >
              {/* Daily header & calendar strip */}
              <div className="rounded-2xl border border-gray-150 bg-white p-4 dark:border-gray-800 dark:bg-gray-900 shadow-3xs">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-4">
                  <div>
                    <h1 className="text-lg font-black text-gray-900 dark:text-gray-150 block">{headerDateString}</h1>
                    <p className="text-3xs text-gray-400">Tap specific days below to back-register completed habits</p>
                  </div>
                  
                  {/* Time of Day routine filters */}
                  <div className="mt-3 sm:mt-0 flex flex-wrap gap-1 bg-gray-100 dark:bg-gray-950 p-1 rounded-xl">
                    {([
                      { id: 'all', name: 'All routines' },
                      { id: 'morning', name: 'Morning' },
                      { id: 'afternoon', name: 'Afternoon' },
                      { id: 'evening', name: 'Evening' }
                    ] as const).map(filter => (
                      <button
                        key={filter.id}
                        onClick={() => setSelectedTimeOfDay(filter.id)}
                        className={`rounded-lg px-2.5 py-1 text-3xs font-extrabold transition-all capitalize select-none ${
                          selectedTimeOfDay === filter.id
                            ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-zinc-100 shadow-3xs'
                            : 'text-gray-500 hover:text-gray-800 dark:text-gray-400 dark:hover:text-zinc-200'
                        }`}
                      >
                        {filter.name}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Mini Calendar Week Strip Slider */}
                <div className="grid grid-cols-7 gap-1.5" id="calendar-week-strip">
                  {calendarDays.map(day => (
                    <button
                      key={day.date}
                      onClick={() => setSelectedDate(day.date)}
                      className={`flex flex-col items-center py-2.5 rounded-xl transition-all scale-100 cursor-pointer ${
                        day.isSelected
                          ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/10'
                          : 'bg-gray-50 dark:bg-gray-850 hover:bg-gray-100 dark:hover:bg-gray-800'
                      }`}
                    >
                      <span className={`text-4xs font-bold uppercase select-none ${day.isSelected ? 'text-indigo-100' : 'text-gray-400'}`}>
                        {day.dayName}
                      </span>
                      <span className="text-sm font-black tracking-tight block mt-0.5">{day.dayNum}</span>
                      
                      {/* Glow indicator completion progress */}
                      <div className="mt-1.5 flex h-2 w-full justify-center">
                        {day.completionRatio > 0 ? (
                          <div
                            className={`h-1.5 w-1.5 rounded-full transition ${
                              day.isSelected
                                ? 'bg-white'
                                : day.completionRatio >= 1
                                ? 'bg-emerald-500 animate-pulse'
                                : 'bg-indigo-500'
                            }`}
                          />
                        ) : (
                          <div className="h-1.5 w-1.5 rounded-full bg-transparent" />
                        )}
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Core habits grid map */}
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-xs font-black uppercase tracking-wider text-gray-400">
                    My Daily Habits ({filteredHabits.length})
                  </h2>
                  <button
                    onClick={() => {
                      setEditingHabit(null);
                      setIsFormOpen(true);
                    }}
                    className="flex items-center space-x-1 rounded-xl bg-indigo-50 dark:bg-indigo-950/20 px-3 py-1.5 text-3xs font-extrabold text-indigo-600 dark:text-indigo-400 hover:bg-indigo-100 dark:hover:bg-indigo-950/40 transition-all border border-indigo-100/40"
                  >
                    <LucideIcon name="Flame" size={12} />
                    <span>Quick Add Habit</span>
                  </button>
                </div>

                {filteredHabits.length > 0 ? (
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2" id="habits-today-grid">
                    {filteredHabits.map(h => (
                      <HabitCard
                        key={h.id}
                        habit={h}
                        log={logs.find(l => l.habitId === h.id && l.date === selectedDate)}
                        onUpdateProgress={handleUpdateProgress}
                        onDeleteHabit={handleArchiveHabit}
                        onEditHabit={(h) => {
                          setEditingHabit(h);
                          setIsFormOpen(true);
                        }}
                        currentStreak={calculateStreak(h.id, logs).current}
                      />
                    ))}
                  </div>
                ) : (
                  <div className="rounded-2xl border border-dashed border-gray-225 bg-white p-12 text-center dark:border-gray-800 dark:bg-gray-900 select-none">
                    <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-gray-50 text-gray-400 dark:bg-gray-850">
                      <LucideIcon name="Compass" size={24} className="rotate-45" />
                    </div>
                    <h3 className="mt-4 text-xs font-bold text-gray-800 dark:text-gray-200">No Habituations Registered Here</h3>
                    <p className="mt-1 text-4xs text-gray-400 max-w-xs mx-auto">
                      There are no habits active for this time bracket or day. Add some habits to begin!
                    </p>
                    <button
                      onClick={() => {
                        setEditingHabit(null);
                        setIsFormOpen(true);
                      }}
                      className="mt-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 text-2xs font-extrabold shadow-sm"
                    >
                      Form Your First Habit
                    </button>
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {activeTab === 'habits' && (
            <motion.div
              key="habits-manager"
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              transition={{ duration: 0.15 }}
              className="space-y-4"
            >
              <div className="flex items-center justify-between">
                <div>
                  <h1 className="text-base font-extrabold text-gray-900 dark:text-gray-50">Habit Architecture Directory</h1>
                  <p className="text-3xs text-gray-400">Total catalog of routine goals with target intervals</p>
                </div>
                <button
                  onClick={() => {
                    setEditingHabit(null);
                    setIsFormOpen(true);
                  }}
                  className="rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white px-4.5 py-2.5 text-2xs font-extrabold shadow-sm transition"
                >
                  Create Habit
                </button>
              </div>

              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                {habits.filter(h => !h.isArchived).map(h => (
                  <div
                    key={h.id}
                    className="rounded-2xl border border-gray-150 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 flex items-center justify-between hover:border-gray-300 transition-all shadow-3xs"
                  >
                    <div className="flex items-center space-x-3.5 min-w-0">
                      <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50 text-indigo-500 shrink-0 dark:bg-indigo-950/20 dark:text-indigo-400">
                        <LucideIcon name={h.icon} size={20} />
                      </div>
                      <div className="min-w-0">
                        <h4 className="font-extrabold text-xs text-gray-900 truncate dark:text-gray-50">{h.name}</h4>
                        <div className="flex items-center space-x-2 mt-0.5 text-4xs font-bold tracking-normal uppercase shrink-0 text-gray-400">
                          <span className="capitalize">{h.type}</span>
                          <span>•</span>
                          <span>{h.type === 'timer' ? `${h.targetValue / 60} mins` : `${h.targetValue} ${h.targetUnit}`}</span>
                          <span>•</span>
                          <span className="capitalize">Route: {h.timeOfDay}</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center space-x-1 shrink-0">
                      <button
                        onClick={() => {
                          setEditingHabit(h);
                          setIsFormOpen(true);
                        }}
                        className="rounded-lg p-2 text-gray-400 hover:bg-gray-50 hover:text-gray-700 dark:hover:bg-gray-800 dark:hover:text-zinc-200 transition"
                        title="Edit Schema"
                      >
                        <LucideIcon name="Activity" size={14} />
                      </button>
                      <button
                        onClick={() => {
                          handleArchiveHabit(h.id);
                        }}
                        className="rounded-lg p-2 text-red-500 hover:bg-red-50 hover:text-red-700 dark:hover:bg-red-950/20 transition-all"
                        title="Archive"
                      >
                        <LucideIcon name="Flame" size={14} className="rotate-180" />
                      </button>
                    </div>
                  </div>
                ))}

                {habits.filter(h => !h.isArchived).length === 0 && (
                  <div className="col-span-full border border-dashed border-gray-200 rounded-3xl p-12 text-center text-gray-400 bg-white dark:bg-gray-900 dark:border-gray-800 font-medium">
                    No active habits are configured. Click the button above to launch one.
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {activeTab === 'stats' && (
            <motion.div
              key="stats-board"
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              transition={{ duration: 0.15 }}
            >
              <div className="mb-4">
                <h1 className="text-base font-extrabold text-gray-900 dark:text-gray-50 flex items-center">
                  <LucideIcon name="Coins" size={18} className="mr-2 text-indigo-500" />
                  Habit Analytics Dashboard & Achievements
                </h1>
                <p className="text-3xs text-gray-400">Track milestones, check-ins ratios and consistency indices</p>
              </div>

              <StatsPanel habits={habits} logs={logs} badges={badges} />
            </motion.div>
          )}

          {activeTab === 'settings' && (
            <motion.div
              key="settings-board"
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              transition={{ duration: 0.15 }}
            >
              <div className="mb-4">
                <h1 className="text-base font-extrabold text-gray-900 dark:text-gray-50">Profile Preferences</h1>
                <p className="text-3xs text-gray-400">Configure parameters, clear tracking arrays, or back up JSON database structures</p>
              </div>

              <SettingsPanel
                settings={settings}
                onUpdateSettings={(newS) => saveSettings({ ...settings, ...newS })}
                habits={habits}
                logs={logs}
                onImportDatabase={handleImportDatabase}
                onFactoryReset={handleFactoryReset}
              />
            </motion.div>
          )}
        </AnimatePresence>

      </main>

      {/* 3. Mobile Navigation Bottom Bar */}
      <footer className="fixed bottom-0 inset-x-0 z-30 border-t border-gray-150 bg-white/95 py-2 backdrop-blur-md md:hidden dark:border-gray-850 dark:bg-gray-950/90 shadow-lg">
        <div className="grid grid-cols-4 text-center">
          {([
            { id: 'daily', name: 'Today Board', icon: 'CheckCircle2' },
            { id: 'habits', name: 'Habits list', icon: 'Activity' },
            { id: 'stats', name: 'Analytics', icon: 'Coins' },
            { id: 'settings', name: 'Settings panel', icon: 'Sparkles' }
          ] as const).map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex flex-col items-center justify-center py-1 transition ${
                activeTab === tab.id
                  ? 'text-indigo-600 dark:text-indigo-400 scale-105 font-bold'
                  : 'text-gray-400 hover:text-gray-600 dark:text-gray-500'
              }`}
            >
              <LucideIcon name={tab.icon} size={18} />
              <span className="text-4xs mt-1 block select-none font-bold uppercase tracking-wide leading-none">{tab.name.split(' ')[0]}</span>
            </button>
          ))}
        </div>
      </footer>

      {/* Habit Create / Edit Modal */}
      <HabitFormModal
        isOpen={isFormOpen}
        onClose={() => {
          setIsFormOpen(false);
          setEditingHabit(null);
        }}
        onSubmit={handleCreateOrUpdateHabit}
        editingHabit={editingHabit}
      />

      {/* Confirmation of Habit Archiving */}
      <ConfirmDialog
        isOpen={archiveHabitId !== null}
        title="Archive Habit"
        message={`Are you sure you want to archive "${habits.find(h => h.id === archiveHabitId)?.name ?? ''}"? Historical check-in stats will be preserved safely.`}
        confirmText="Archive"
        isDanger={true}
        onConfirm={handleConfirmArchive}
        onCancel={() => setArchiveHabitId(null)}
      />

      {/* Achievement Medals celebrate overlay alert toast */}
      <AnimatePresence>
        {unlockedBadgeToast && (
          <motion.div
            initial={{ opacity: 0, y: 100, scale: 0.8 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -40, scale: 0.9 }}
            className="fixed bottom-24 md:bottom-8 right-4 left-4 md:left-auto md:w-96 z-50 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 shadow-xl flex items-center space-x-4 dark:border-emerald-900/60 dark:bg-zinc-900"
          >
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-emerald-500 text-white shadow-md animate-bounce">
              <LucideIcon name={unlockedBadgeToast.icon} size={20} />
            </div>
            <div>
              <span className="text-4xs font-mono font-black text-emerald-600 dark:text-emerald-400 tracking-wider block uppercase">Achievement Unlocked!</span>
              <h3 className="text-xs font-bold text-gray-900 dark:text-white leading-tight">
                {unlockedBadgeToast.title}
              </h3>
              <p className="text-3xs text-gray-500 dark:text-gray-400 mt-0.5">
                {unlockedBadgeToast.description}
              </p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
