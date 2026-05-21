import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Habit, HabitType, TimeOfDay } from '../types';
import { CATEGORY_SPECS, COLOR_OPTIONS, ICON_OPTIONS } from '../utils';
import LucideIcon from './LucideIcon';

interface HabitFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (habitData: Omit<Habit, 'id' | 'createdAt' | 'isArchived'>) => void;
  editingHabit?: Habit | null;
}

export default function HabitFormModal({
  isOpen,
  onClose,
  onSubmit,
  editingHabit
}: HabitFormModalProps) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('health');
  const [type, setType] = useState<HabitType>('boolean');
  const [timeOfDay, setTimeOfDay] = useState<TimeOfDay>('anytime');
  
  // Display target input in standard user units (e.g., minutes of meditation, times read)
  const [targetInput, setTargetInput] = useState(1);
  const [targetUnit, setTargetUnit] = useState('times');

  const [color, setColor] = useState('emerald');
  const [icon, setIcon] = useState('Activity');

  // Trigger default presets when category shifts to help make the UI feel smooth
  useEffect(() => {
    if (!editingHabit) {
      if (category === 'health') {
        setColor('emerald');
        setIcon('Dumbbell');
        setTargetUnit('times');
      } else if (category === 'mind') {
        setColor('violet');
        setIcon('Brain');
        setTargetUnit('mins');
        setType('timer');
        setTargetInput(10);
      } else if (category === 'learning') {
        setColor('amber');
        setIcon('BookOpen');
        setTargetUnit('pages');
        setType('numeric');
        setTargetInput(10);
      } else if (category === 'creativity') {
        setColor('pink');
        setIcon('Sparkles');
        setTargetUnit('hours');
      } else if (category === 'finance') {
        setColor('cyan');
        setIcon('Coins');
        setTargetUnit('USD');
      }
    }
  }, [category, editingHabit]);

  // Handle preset loading when editing an existing habit
  useEffect(() => {
    if (editingHabit) {
      setName(editingHabit.name);
      setDescription(editingHabit.description || '');
      setCategory(editingHabit.category);
      setType(editingHabit.type);
      setTimeOfDay(editingHabit.timeOfDay);
      setColor(editingHabit.color);
      setIcon(editingHabit.icon);
      setTargetUnit(editingHabit.targetUnit);
      
      // If timer type, convert seconds back to minutes for ease of editing
      if (editingHabit.type === 'timer') {
        setTargetInput(Math.round(editingHabit.targetValue / 60));
      } else {
        setTargetInput(editingHabit.targetValue);
      }
    } else {
      // Clear fields to pristine state
      setName('');
      setDescription('');
      setCategory('health');
      setType('boolean');
      setTimeOfDay('anytime');
      setTargetInput(1);
      setTargetUnit('times');
      setColor('emerald');
      setIcon('Activity');
    }
  }, [editingHabit, isOpen]);

  // Adjust default target units when toggling type
  const handleTypeChange = (selectedType: HabitType) => {
    setType(selectedType);
    if (selectedType === 'timer') {
      setTargetUnit('mins');
      setTargetInput(15);
    } else if (selectedType === 'numeric') {
      setTargetUnit('times');
      setTargetInput(5);
    } else {
      setTargetUnit('times');
      setTargetInput(1);
    }
  };

  const handleFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    // Calculate final target value based on input specs
    let targetValue = Number(targetInput);
    if (type === 'timer') {
      targetValue = targetInput * 60; // convert standard minutes to seconds
    }

    onSubmit({
      name: name.trim(),
      description: description.trim(),
      category,
      type,
      timeOfDay,
      targetValue: isNaN(targetValue) || targetValue <= 0 ? 1 : targetValue,
      targetUnit: targetUnit.trim() || 'times',
      color,
      icon,
    });
    
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Black Backdrop overlay */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.5 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-40 bg-black"
            onClick={onClose}
          />

          {/* Form Modal */}
          <motion.div
            id="habit-form-modal"
            initial={{ opacity: 0, scale: 0.95, y: 30 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 30 }}
            transition={{ type: 'spring', damping: 25, stiffness: 350 }}
            className="fixed inset-x-4 bottom-4 top-4 z-50 mx-auto flex max-w-lg flex-col rounded-3xl bg-slate-50 p-6 shadow-xl dark:bg-gray-900 overflow-hidden border border-gray-150 dark:border-gray-800"
          >
            {/* Header */}
            <div className="flex items-center justify-between pb-4 border-b border-gray-150 dark:border-gray-800">
              <div>
                <h2 className="text-base font-bold text-gray-900 dark:text-gray-50 flex items-center">
                  <LucideIcon name={editingHabit ? "Activity" : "Sparkles"} size={18} className="mr-2 text-indigo-500" />
                  {editingHabit ? 'Modify Habit' : 'Form New Habit'}
                </h2>
                <p className="text-3xs text-gray-400">Specify details below to track progress</p>
              </div>
              <button
                onClick={onClose}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-500 transition-all"
              >
                <LucideIcon name="Sparkles" size={14} className="rotate-45" />
              </button>
            </div>

            {/* Scrollable Form Body */}
            <form onSubmit={handleFormSubmit} className="flex-1 overflow-y-auto py-4 space-y-4 pr-1">
              
              {/* Name */}
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-750 dark:text-gray-300 block">Habit Label *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Read 15 pages feed, Do 20 pushups"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full rounded-xl border border-gray-225 bg-white px-4 py-2.5 text-sm outline-hidden focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-50"
                />
              </div>

              {/* Description */}
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-750 dark:text-gray-300 block">Brief Intent / Description</label>
                <textarea
                  placeholder="Why is this meaningful to your life? What trigger cues will you use?"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  rows={2}
                  className="w-full rounded-xl border border-gray-225 bg-white px-4 py-2 text-xs outline-hidden focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-50 resize-none"
                />
              </div>

              {/* Grid: Category & Time of Day */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-gray-700 dark:text-gray-300 block">Category Focus</label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-xs outline-hidden text-gray-900 dark:text-gray-100 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 dark:border-gray-850 dark:bg-gray-950"
                  >
                    {Object.keys(CATEGORY_SPECS).map((id) => (
                      <option 
                        key={id} 
                        value={id} 
                        className="bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100"
                      >
                        {CATEGORY_SPECS[id].name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-bold text-gray-700 dark:text-gray-300 block">Time of Day</label>
                  <select
                    value={timeOfDay}
                    onChange={(e) => setTimeOfDay(e.target.value as TimeOfDay)}
                    className="w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-xs outline-hidden text-gray-900 dark:text-gray-100 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 dark:border-gray-850 dark:bg-gray-950"
                  >
                    <option value="anytime" className="bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100">Anytime / All Day</option>
                    <option value="morning" className="bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100">Morning Routine</option>
                    <option value="afternoon" className="bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100">Afternoon Block</option>
                    <option value="evening" className="bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100">Evening Routine</option>
                  </select>
                </div>
              </div>

              {/* Behavior Selector (Type) */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-750 dark:text-gray-300 block">Tracking System Type</label>
                <div className="grid grid-cols-3 gap-2">
                  {(['boolean', 'numeric', 'timer'] as HabitType[]).map((t) => (
                    <button
                      key={t}
                      type="button"
                      onClick={() => handleTypeChange(t)}
                      className={`flex flex-col items-center justify-center p-2.5 rounded-xl border text-center transition-all ${
                        type === t
                          ? 'border-indigo-500 bg-indigo-500/10 text-indigo-600 dark:text-indigo-400'
                          : 'border-gray-200 bg-white hover:bg-gray-50 dark:border-gray-800 dark:bg-gray-950 text-gray-500 dark:text-gray-400'
                      }`}
                    >
                      <LucideIcon
                        name={t === 'boolean' ? 'CheckCircle2' : t === 'numeric' ? 'Flame' : 'Activity'}
                        size={16}
                        className="mb-1"
                      />
                      <span className="text-3xs font-bold capitalize select-none leading-none">
                        {t === 'boolean' ? 'Yes / No' : t === 'numeric' ? 'Counter' : 'Timer Code'}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Conditional parameters (Numeric Targets / Minutes timer values) */}
              {type !== 'boolean' && (
                <div className="grid grid-cols-2 gap-3 p-3 rounded-2xl bg-gray-100 dark:bg-gray-950">
                  <div className="space-y-1">
                    <label className="text-2xs font-extrabold text-gray-600 dark:text-gray-450 block">
                      {type === 'timer' ? 'Target minutes' : 'Goal Number Target'}
                    </label>
                    <input
                      type="number"
                      min={1}
                      required
                      value={targetInput}
                      onChange={(e) => setTargetInput(Math.max(1, parseInt(e.target.value) || 1))}
                      className="w-full rounded-xl border border-gray-300 bg-white px-3 py-1.5 text-xs outline-hidden dark:border-gray-800 dark:bg-gray-900 dark:text-gray-100"
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="text-2xs font-extrabold text-gray-600 dark:text-gray-450 block">Target Unit label</label>
                    <input
                      type="text"
                      required
                      disabled={type === 'timer'}
                      value={targetUnit}
                      onChange={(e) => setTargetUnit(e.target.value)}
                      className="w-full rounded-xl border border-gray-300 bg-white px-3 py-1.5 text-xs outline-hidden dark:border-gray-800 dark:bg-gray-900 dark:text-gray-100 disabled:opacity-50"
                    />
                  </div>
                </div>
              )}

              {/* Color Accents selection */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-750 dark:text-gray-300 block">Personal Vibe Color Accent</label>
                <div className="flex flex-wrap gap-2.5">
                  {COLOR_OPTIONS.map((c) => (
                    <button
                      key={c.id}
                      type="button"
                      onClick={() => setColor(c.id)}
                      className={`h-7 w-7 rounded-full border-2 ${c.bg} ${
                        color === c.id ? 'border-indigo-600 scale-110 shadow-xs' : 'border-transparent opacity-85'
                      } transition-all`}
                    />
                  ))}
                </div>
              </div>

              {/* SVG Glyph Icon Grid */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-750 dark:text-gray-300 block">Choose Graphic Icon Representation</label>
                <div className="grid grid-cols-8 gap-2 bg-white dark:bg-gray-950 p-3 rounded-2xl border border-gray-200 dark:border-gray-800 max-h-36 overflow-y-auto">
                  {ICON_OPTIONS.map((ico) => (
                    <button
                      key={ico}
                      type="button"
                      onClick={() => setIcon(ico)}
                      className={`flex h-8 items-center justify-center rounded-lg border transition ${
                        icon === ico
                          ? 'border-indigo-500 bg-indigo-50 text-indigo-500 dark:bg-indigo-950/40 dark:text-indigo-400 font-extrabold scale-110'
                          : 'border-transparent text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-850'
                      }`}
                    >
                      <LucideIcon name={ico} size={16} />
                    </button>
                  ))}
                </div>
              </div>

            </form>

            {/* Bottom Form Actions */}
            <div className="pt-4 border-t border-gray-150 dark:border-gray-800 flex items-center justify-end space-x-3 shrink-0">
              <button
                type="button"
                onClick={onClose}
                className="rounded-xl px-4 py-2.5 text-xs font-medium text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-850 transition"
              >
                Go Back
              </button>
              <button
                id="btn-submit-habit"
                onClick={handleFormSubmit}
                className="rounded-xl bg-indigo-600 hover:bg-indigo-700 shadow-sm shadow-indigo-600/20 text-white px-5 py-2.5 text-xs font-bold transition-all"
              >
                {editingHabit ? 'Apply Revisions' : 'Launch New Habit'}
              </button>
            </div>

          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
