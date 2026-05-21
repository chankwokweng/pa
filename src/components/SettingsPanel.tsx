import React, { useRef, useState } from 'react';
import { AppSettings, Habit, HabitLog } from '../types';
import LucideIcon from './LucideIcon';
import ConfirmDialog from './ConfirmDialog';

interface SettingsPanelProps {
  settings: AppSettings;
  onUpdateSettings: (newSettings: Partial<AppSettings>) => void;
  habits: Habit[];
  logs: HabitLog[];
  onImportDatabase: (importedHabits: Habit[], importedLogs: HabitLog[]) => void;
  onFactoryReset: () => void;
}

export default function SettingsPanel({
  settings,
  onUpdateSettings,
  habits,
  logs,
  onImportDatabase,
  onFactoryReset
}: SettingsPanelProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [copied, setCopied] = useState(false);
  
  const [showImportConfirm, setShowImportConfirm] = useState(false);
  const [showResetConfirm, setShowResetConfirm] = useState(false);
  const [pendingPayload, setPendingPayload] = useState<{ habits: Habit[]; logs: HabitLog[]; settings?: any } | null>(null);
  const [importStatusMessage, setImportStatusMessage] = useState<string | null>(null);

  // Export full DB state as JSON file
  const handleExportDatabase = () => {
    try {
      const dataStr = JSON.stringify({
        version: '1.0.0',
        exportedAt: new Date().toISOString(),
        habits,
        logs,
        settings
      }, null, 2);

      const blob = new Blob([dataStr], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `AuraHabit_Backup_${new Date().toISOString().split('T')[0]}.json`;
      
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    } catch (err) {
      alert('Failed to export backup. Error details: ' + err);
    }
  };

  // Import active JSON back to DB state
  const handleImportDatabase = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const payload = JSON.parse(event.target?.result as string);
        if (Array.isArray(payload.habits) && Array.isArray(payload.logs)) {
          setPendingPayload(payload);
          setShowImportConfirm(true);
        } else {
          setImportStatusMessage('Invalid backup schema definition. Missing main array structures.');
        }
      } catch (err) {
        setImportStatusMessage('Failed parsing backup. Ensure the file is a valid AuraHabit JSON backup.');
      }
    };
    reader.readAsText(file);
  };

  const triggerFileInput = () => {
    fileInputRef.current?.click();
  };

  return (
    <div className="space-y-6" id="settings-panel-container">
      {/* 1. Account Settings */}
      <div className="rounded-2xl border border-gray-150 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-3xs">
        <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100 flex items-center">
          <LucideIcon name="Smile" size={16} className="mr-2 text-indigo-500" />
          User Profile Context
        </h3>
        <p className="text-3xs text-gray-400 mt-0.5">Customize how AuraHabit addresses you throughout the dashboard</p>

        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="space-y-1">
            <label className="text-2xs font-extrabold text-gray-400 block">Your Name / Title</label>
            <input
              type="text"
              value={settings.userName}
              onChange={(e) => onUpdateSettings({ userName: e.target.value })}
              className="w-full rounded-xl border border-gray-225 bg-white px-3.5 py-2 text-xs outline-hidden focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-100"
            />
          </div>

          <div className="space-y-1">
            <label className="text-2xs font-extrabold text-gray-400 block font-medium">Daily Motivational Quotes</label>
            <div className="flex items-center pt-2">
              <label className="relative inline-flex items-center cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={settings.showQuote}
                  onChange={(e) => onUpdateSettings({ showQuote: e.target.checked })}
                  className="sr-only peer"
                />
                <div className="w-9 h-5 bg-gray-200 peer-focus:outline-hidden rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all dark:border-gray-600 peer-checked:bg-indigo-600" />
                <span className="ml-2.5 text-xs text-gray-700 dark:text-gray-300">Show inspirational quotes banner</span>
              </label>
            </div>
          </div>
        </div>
      </div>

      {/* 2. Database backups & sync */}
      <div className="rounded-2xl border border-gray-150 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-3xs">
        <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100 flex items-center">
          <LucideIcon name="Coins" size={16} className="mr-2 text-indigo-500" />
          Offline-First Storage Sync
        </h3>
        <p className="text-3xs text-gray-400 mt-0.5">Manage backups locally without relying on external cloud data trackers</p>

        <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
          {/* Export */}
          <button
            onClick={handleExportDatabase}
            className="flex items-center justify-between rounded-xl border border-gray-200 bg-linear-to-b from-white to-gray-50 p-4 hover:bg-gray-100 transition shadow-2xs dark:border-gray-800 dark:from-gray-900 dark:to-gray-850"
          >
            <div className="text-left">
              <span className="text-xs font-bold text-gray-800 dark:text-gray-100 block">Export Full Database</span>
              <span className="text-3xs text-gray-400 block mt-0.5">Download habits & log history as a .json backup file</span>
            </div>
            <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-50 text-indigo-500 dark:bg-indigo-950/20 dark:text-indigo-400">
              <LucideIcon name="Flame" className="rotate-180" size={16} />
            </span>
          </button>

          {/* Import */}
          <div>
            <button
              onClick={triggerFileInput}
              className="flex w-full items-center justify-between rounded-xl border border-gray-200 bg-linear-to-b from-white to-gray-50 p-4 hover:bg-gray-100 transition shadow-2xs dark:border-gray-800 dark:from-gray-900 dark:to-gray-850"
            >
              <div className="text-left">
                <span className="text-xs font-bold text-gray-800 dark:text-gray-100 block">Import Local Backup</span>
                <span className="text-3xs text-gray-400 block mt-0.5">Restore configurations from an existing .json backup</span>
              </div>
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-50 text-violet-500 dark:bg-violet-950/20 dark:text-violet-400">
                <LucideIcon name="Compass" className="rotate-180" size={16} />
              </span>
            </button>
            <input
              type="file"
              ref={fileInputRef}
              onChange={handleImportDatabase}
              accept=".json"
              className="hidden"
            />
          </div>
        </div>
      </div>

      {/* 3. Mobile PWA installation Guide */}
      <div className="rounded-2xl border border-indigo-100 bg-indigo-50/20 p-5 dark:border-indigo-900/30 dark:bg-indigo-950/10">
        <h3 className="text-sm font-semibold text-gray-900 dark:text-indigo-300 flex items-center">
          <LucideIcon name="Compass" size={16} className="mr-2 text-indigo-500" />
          Install App On Mobile Devices (iOS & Android)
        </h3>
        <p className="text-3xs text-indigo-400 mt-0.5">Run AuraHabit as a full screen native app completely offline</p>

        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
          {/* iOS Safari */}
          <div className="space-y-1.5 text-xs">
            <div className="flex items-center space-x-2 font-bold text-gray-800 dark:text-zinc-200">
              <LucideIcon name="GlassWater" size={14} className="text-slate-400 shrink-0" />
              <span>Apple iOS (Safari browser)</span>
            </div>
            <ol className="list-decimal pl-4 space-y-1 text-gray-500 dark:text-gray-400 text-3xs">
              <li className="leading-tight">Open the browser link inside standard <b>Apple Safari</b>.</li>
              <li className="leading-tight">Tap the blue <b className="text-gray-700 dark:text-white">Share icon button</b> in Safari navigation toolbar.</li>
              <li className="leading-tight">Scroll and choose <b className="text-gray-700 dark:text-white">"Add to Home Screen"</b>.</li>
              <li className="leading-tight">Launch the AuraHabit icon from your phone panel to trigger offline mode!</li>
            </ol>
          </div>

          {/* Android Chrome */}
          <div className="space-y-1.5 text-xs">
            <div className="flex items-center space-x-2 font-bold text-gray-800 dark:text-zinc-200">
              <LucideIcon name="Activity" size={14} className="text-slate-400 shrink-0" />
              <span>Google Android (Chrome browser)</span>
            </div>
            <ol className="list-decimal pl-4 space-y-1 text-gray-500 dark:text-gray-400 text-3xs">
              <li className="leading-tight">Open this page link inside <b>Google Chrome</b>.</li>
              <li className="leading-tight">Tap the <b className="text-gray-700 dark:text-white">Three-Dot Menu icon</b> on the Chrome toolbar top-right.</li>
              <li className="leading-tight">Tap <b className="text-gray-700 dark:text-white">"Install app"</b> or <b className="text-gray-700 dark:text-white">"Add to Home screen"</b>.</li>
              <li className="leading-tight">Review permissions and confirm. Launch standalone from home grid.</li>
            </ol>
          </div>
        </div>
      </div>

      {/* 4. Factory Reset settings */}
      <div className="rounded-2xl border border-red-100 bg-red-50/20 p-5 dark:border-red-950/20 dark:bg-red-950/10">
        <h3 className="text-sm font-semibold text-red-650 dark:text-red-400 flex items-center">
          <LucideIcon name="Flame" size={16} className="mr-2 text-red-500" />
          Factory Reset State
        </h3>
        <p className="text-3xs text-red-400 mt-0.5">Wipes local database directories and installs default mock data</p>

        <div className="mt-4 flex items-center justify-between">
          <div className="text-left text-xs text-gray-500 dark:text-gray-400 leading-tight mr-4">
            Warning: This action will permanently erase your custom tracks, total streak calculations, and all logged completions. This is irreversible.
          </div>
          <button
            onClick={() => {
              setShowResetConfirm(true);
            }}
            className="rounded-xl bg-red-600 hover:bg-red-700 text-white px-4 py-2 font-bold text-xs shrink-0 transition"
          >
            Reset Database Storage
          </button>
        </div>
      </div>

      {/* Confirmation Dialogs */}
      <ConfirmDialog
        isOpen={showImportConfirm}
        title="Import JSON Backup"
        message="Are you sure you want to import this local backup file? This replaces your current tracking habits list and history counters and restarts your analytics."
        onConfirm={() => {
          if (pendingPayload) {
            onImportDatabase(pendingPayload.habits, pendingPayload.logs);
            if (pendingPayload.settings) {
              onUpdateSettings(pendingPayload.settings);
            }
            setImportStatusMessage('AuraHabit database imported successfully!');
          }
          setShowImportConfirm(false);
          setPendingPayload(null);
        }}
        onCancel={() => {
          setShowImportConfirm(false);
          setPendingPayload(null);
        }}
      />

      <ConfirmDialog
        isOpen={showResetConfirm}
        title="Wipe Tracker History"
        message="Are you sure you want to perform a factory reset? This irreversibly clears all custom routines, logged checkpoints, and accumulated habit streaks."
        isDanger={true}
        confirmText="Yes, Factory Reset"
        onConfirm={() => {
          onFactoryReset();
          setShowResetConfirm(false);
          setImportStatusMessage('Database reset to defaults successfully.');
        }}
        onCancel={() => setShowResetConfirm(false)}
      />

      {/* Modern Status Notification Modal instead of Native alerts */}
      {importStatusMessage && (
        <div className="fixed bottom-20 left-1/2 -translate-x-1/2 z-50 rounded-xl bg-gray-900 border border-gray-800 text-white px-4 py-3 text-2xs font-extrabold shadow-lg flex items-center space-x-2 animate-bounce">
          <LucideIcon name="Compass" size={14} className="text-indigo-400" />
          <span>{importStatusMessage}</span>
          <button
            onClick={() => setImportStatusMessage(null)}
            className="text-gray-400 hover:text-white pl-2"
          >
            ✕
          </button>
        </div>
      )}
    </div>
  );
}
