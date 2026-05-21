import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Habit, HabitLog } from '../types';
import { CATEGORY_SPECS, formatDuration } from '../utils';
import LucideIcon from './LucideIcon';

interface HabitCardProps {
  key?: string;
  habit: Habit;
  log: HabitLog | undefined;
  onUpdateProgress: (habitId: string, newValue: number) => void;
  onDeleteHabit: (habitId: string) => void;
  onEditHabit: (habit: Habit) => void;
  currentStreak: number;
}

export default function HabitCard({
  habit,
  log,
  onUpdateProgress,
  onDeleteHabit,
  onEditHabit,
  currentStreak
}: HabitCardProps) {
  const spec = CATEGORY_SPECS[habit.category] || CATEGORY_SPECS.health;
  const isCompleted = log?.isCompleted || false;
  const currentValue = log?.value || 0;
  const targetValue = habit.targetValue;

  // For timer habits
  const [timerRunning, setTimerRunning] = useState(false);
  const [timeLeft, setTimeLeft] = useState(targetValue - currentValue);
  const intervalRef = useRef<number | null>(null);

  // Sync timeLeft when database changes or progress logs change externally
  useEffect(() => {
    setTimeLeft(Math.max(0, targetValue - currentValue));
  }, [currentValue, targetValue]);

  // Clean timer on unmount
  useEffect(() => {
    return () => {
      if (intervalRef.current) window.clearInterval(intervalRef.current);
    };
  }, []);

  const handleToggleBoolean = () => {
    if (isCompleted) {
      onUpdateProgress(habit.id, 0);
    } else {
      onUpdateProgress(habit.id, 1);
    }
  };

  const handleIncrement = (e: React.MouseEvent) => {
    e.stopPropagation();
    const nextVal = currentValue + 1;
    onUpdateProgress(habit.id, nextVal);
  };

  const handleDecrement = (e: React.MouseEvent) => {
    e.stopPropagation();
    const nextVal = Math.max(0, currentValue - 1);
    onUpdateProgress(habit.id, nextVal);
  };

  // Timer actions
  const toggleTimer = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (timerRunning) {
      // Pause
      setTimerRunning(false);
      if (intervalRef.current) {
        window.clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    } else {
      // Start
      setTimerRunning(true);
      intervalRef.current = window.setInterval(() => {
        setTimeLeft((prev) => {
          const next = prev - 1;
          if (next <= 0) {
            setTimerRunning(false);
            if (intervalRef.current) {
              window.clearInterval(intervalRef.current);
              intervalRef.current = null;
            }
            onUpdateProgress(habit.id, targetValue); // Completed!
            return 0;
          }
          // Periodically save progress (every 5 seconds or on check completed)
          if (next % 5 === 0 || next === 0) {
            onUpdateProgress(habit.id, targetValue - next);
          }
          return next;
        });
      }, 1000);
    }
  };

  const handleTimerReset = (e: React.MouseEvent) => {
    e.stopPropagation();
    setTimerRunning(false);
    if (intervalRef.current) {
      window.clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setTimeLeft(targetValue);
    onUpdateProgress(habit.id, 0);
  };

  const handleTimerFastForward = (e: React.MouseEvent) => {
    e.stopPropagation();
    setTimerRunning(false);
    if (intervalRef.current) {
      window.clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setTimeLeft(0);
    onUpdateProgress(habit.id, targetValue);
  };

  const [showOptions, setShowOptions] = useState(false);

  // Styling dynamically derived
  const colorMap: Record<string, string> = {
    emerald: 'bg-emerald-500 from-emerald-500 to-emerald-600 border-emerald-500 text-emerald-600 focus:ring-emerald-400 focus-visible:ring-emerald-400',
    violet: 'bg-violet-500 from-violet-500 to-violet-600 border-violet-500 text-violet-600 focus:ring-violet-400 focus-visible:ring-violet-400',
    amber: 'bg-amber-500 from-amber-500 to-amber-600 border-amber-500 text-amber-600 focus:ring-amber-400 focus-visible:ring-amber-400',
    pink: 'bg-pink-500 from-pink-500 to-pink-600 border-pink-500 text-pink-600 focus:ring-pink-400 focus-visible:ring-pink-400',
    cyan: 'bg-cyan-500 from-cyan-500 to-cyan-600 border-cyan-500 text-cyan-600 focus:ring-cyan-400 focus-visible:ring-cyan-400',
    rose: 'bg-rose-500 from-rose-500 to-rose-600 border-rose-500 text-rose-600 focus:ring-rose-400 focus-visible:ring-rose-400',
    indigo: 'bg-indigo-500 from-indigo-500 to-indigo-600 border-indigo-500 text-indigo-600 focus:ring-indigo-400 focus-visible:ring-indigo-400',
  };

  const activeColorClass = colorMap[habit.color] || colorMap.indigo;

  return (
    <motion.div
      layout
      id={`habit-card-${habit.id}`}
      initial={{ opacity: 0, y: 15 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      whileHover={{ y: -2 }}
      transition={{ duration: 0.2 }}
      className={`relative overflow-hidden rounded-2xl border bg-white p-5 shadow-sm dark:bg-gray-900 transition-all ${
        isCompleted
          ? 'border-gray-200 dark:border-gray-800 ring-2 ring-offset-2 dark:ring-offset-black' +
            (habit.color === 'emerald' ? ' ring-emerald-400/30' : '') +
            (habit.color === 'violet' ? ' ring-violet-400/30' : '') +
            (habit.color === 'amber' ? ' ring-amber-400/30' : '') +
            (habit.color === 'pink' ? ' ring-pink-400/30' : '') +
            (habit.color === 'cyan' ? ' ring-cyan-400/30' : '') +
            (habit.color === 'rose' ? ' ring-rose-400/30' : '') +
            (habit.color === 'indigo' ? ' ring-indigo-400/30' : '')
          : 'border-gray-150 hover:border-gray-300 dark:border-gray-800 dark:hover:border-gray-700'
      }`}
    >
      {/* Glow Effect when fully completed */}
      {isCompleted && (
        <div className={`absolute -right-12 -top-12 h-32 w-32 rounded-full opacity-10 bg-${habit.color}-400 blur-2xl pointer-events-none`} />
      )}

      {/* Main Grid Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center space-x-3">
          {/* Visual Icon Container */}
          <div
            className={`flex h-11 w-11 items-center justify-center rounded-xl transition-all ${
              isCompleted
                ? activeColorClass.split(' ')[0] + ' text-white shadow-sm'
                : spec.bgColor + ' ' + spec.textColor
            }`}
          >
            <LucideIcon name={habit.icon} size={22} className={isCompleted ? 'animate-pulse' : ''} />
          </div>

          <div>
            <h3 className={`font-semibold leading-tight text-gray-900 dark:text-gray-100 ${isCompleted ? 'line-through text-gray-400 dark:text-gray-500' : ''}`}>
              {habit.name}
            </h3>
            <div className="mt-1 flex items-center space-x-2">
              <span className={`inline-flex items-center rounded-md px-1.5 py-0.5 text-2xs font-medium uppercase tracking-wide border ${spec.bgColor} ${spec.textColor} ${spec.borderColor}`}>
                {spec.name}
              </span>
              {habit.timeOfDay !== 'anytime' && (
                <span className="inline-flex items-center space-x-1 text-2xs text-gray-400 dark:text-gray-500 font-medium">
                  <LucideIcon name={habit.timeOfDay === 'morning' ? 'Coffee' : habit.timeOfDay === 'afternoon' ? 'Compass' : 'Moon'} size={10} />
                  <span className="capitalize">{habit.timeOfDay}</span>
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Action Toggle Dots Button */}
        <div className="relative">
          <button
            id={`btn-options-${habit.id}`}
            onClick={() => setShowOptions(!showOptions)}
            className="rounded-full p-1.5 text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-600 transition"
          >
            <LucideIcon name="Sparkles" size={16} className="rotate-45" />
          </button>

          <AnimatePresence>
            {showOptions && (
              <>
                <div className="fixed inset-0 z-10" onClick={() => setShowOptions(false)} />
                <motion.div
                  initial={{ opacity: 0, scale: 0.95, y: -10 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95, y: -10 }}
                  transition={{ duration: 0.15 }}
                  className="absolute right-0 top-8 z-20 w-40 origin-top-right rounded-xl border border-gray-150 bg-white dark:bg-gray-800 p-2 shadow-lg ring-1 ring-black/5 dark:border-gray-700"
                >
                  <button
                    onClick={() => {
                      onEditHabit(habit);
                      setShowOptions(false);
                    }}
                    className="flex w-full items-center space-x-2.5 rounded-lg px-2.5 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50"
                  >
                    <LucideIcon name="Activity" size={14} className="text-gray-400" />
                    <span>Edit Details</span>
                  </button>
                  <button
                    onClick={() => {
                      onDeleteHabit(habit.id);
                      setShowOptions(false);
                    }}
                    className="flex w-full items-center space-x-2.5 rounded-lg px-2.5 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                  >
                    <LucideIcon name="Flame" size={14} className="text-red-500" />
                    <span>Archive / Clear</span>
                  </button>
                </motion.div>
              </>
            )}
          </AnimatePresence>
        </div>
      </div>

      {descriptionWithClamp(habit.description)}

      {/* Conditional Interface logic based on Habit Type */}
      <div className="mt-4 flex items-center justify-between border-t border-gray-100 dark:border-gray-850 pt-4">
        {/* Streak Details */}
        <div className="flex items-center space-x-1.5">
          <LucideIcon
            name="Flame"
            size={18}
            className={`${currentStreak > 0 ? 'text-amber-500 animate-bounce' : 'text-gray-350 dark:text-gray-600'}`}
          />
          <div>
            <span className="text-xs font-bold text-gray-900 dark:text-gray-150">{currentStreak}</span>
            <span className="text-3xs text-gray-400 block -mt-1 font-medium select-none">STREAK</span>
          </div>
        </div>

        {/* Right side: trackers */}
        <div className="flex items-center space-x-2">
          {habit.type === 'boolean' && (
            <button
              id={`toggle-bool-${habit.id}`}
              onClick={handleToggleBoolean}
              className={`flex h-9 px-4 items-center justify-center rounded-xl border text-xs font-semibold shadow-2xs transition-all duration-200 outline-none ${
                isCompleted
                  ? 'bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-950 border-gray-900 dark:border-gray-100'
                  : 'bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-750 dark:text-gray-250 border-gray-225 dark:border-gray-700'
              }`}
            >
              <LucideIcon name={isCompleted ? 'CheckCircle2' : 'Activity'} size={14} className="mr-2" />
              {isCompleted ? 'Done' : 'Check Off'}
            </button>
          )}

          {habit.type === 'numeric' && (
            <div className="flex items-center space-x-1.5" id={`counter-${habit.id}`}>
              <button
                onClick={handleDecrement}
                disabled={currentValue <= 0}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 active:scale-95 disabled:opacity-40 transition-all dark:border-gray-750 dark:bg-gray-850 dark:text-gray-350"
              >
                <span className="font-bold text-sm">-</span>
              </button>
              
              <div className="px-2 text-center select-none">
                <span className={`text-xs font-bold ${isCompleted ? 'text-emerald-500' : 'text-gray-800 dark:text-gray-200'}`}>
                  {currentValue}
                </span>
                <span className="text-gray-400 text-2xs block">/ {targetValue} {habit.targetUnit}</span>
              </div>

              <button
                onClick={handleIncrement}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 active:scale-95 transition-all dark:border-gray-750 dark:bg-gray-850 dark:text-gray-350"
              >
                <span className="font-bold text-sm">+</span>
              </button>
            </div>
          )}

          {habit.type === 'timer' && (
            <div className="flex items-center space-x-2">
              {/* Quick controls */}
              <div className="text-right mr-1">
                <span className={`text-xs font-bold block ${isCompleted ? 'text-emerald-500' : 'text-gray-700 dark:text-gray-300'}`}>
                  {isCompleted ? 'Finished' : formatDuration(timeLeft)}
                </span>
                <span className="text-3xs text-gray-400 block -mt-1 uppercase tracking-wide">
                  {isCompleted ? 'Total Time' : `${formatDuration(targetValue)} Target`}
                </span>
              </div>

              {!isCompleted && (
                <div className="flex items-center space-x-1">
                  <button
                    onClick={toggleTimer}
                    className={`flex h-8 w-8 items-center justify-center rounded-lg shadow-sm transition-all text-white ${
                      timerRunning ? 'bg-amber-500 hover:bg-amber-600' : 'bg-indigo-600 hover:bg-indigo-700'
                    }`}
                  >
                    <LucideIcon name={timerRunning ? 'Coins' : 'Activity'} size={14} />
                  </button>
                  {currentValue > 0 && (
                    <button
                      onClick={handleTimerReset}
                      className="flex h-8 w-8 items-center justify-center rounded-lg border border-gray-200 bg-white text-gray-500 hover:bg-gray-100 transition-all dark:border-gray-750 dark:bg-gray-850"
                    >
                      <LucideIcon name="Sparkles" className="rotate-45" size={12} />
                    </button>
                  )}
                  <button
                    onClick={handleTimerFastForward}
                    className="flex h-8 w-8 items-center justify-center rounded-lg border border-gray-200 bg-white text-gray-500 hover:bg-gray-100 transition-all dark:border-gray-750 dark:bg-gray-850"
                    title="Skip to end"
                  >
                    <LucideIcon name="CheckCircle2" size={12} />
                  </button>
                </div>
              )}

              {isCompleted && (
                <button
                  onClick={handleTimerReset}
                  className="flex h-8 px-2.5 items-center justify-center rounded-lg border border-gray-200 bg-white text-2xs text-gray-500 hover:bg-gray-150 transition-all dark:border-gray-750 dark:bg-gray-850 dark:text-gray-300"
                >
                  Reset Time
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </motion.div>
  );
}

function descriptionWithClamp(desc: string) {
  if (!desc) return null;
  return (
    <p className="mt-2 text-xs text-gray-500 dark:text-gray-400 line-clamp-2 md:h-8">
      {desc}
    </p>
  );
}
