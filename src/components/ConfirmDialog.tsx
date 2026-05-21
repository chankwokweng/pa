import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import LucideIcon from './LucideIcon';

interface ConfirmDialogProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void;
  onCancel: () => void;
  isDanger?: boolean;
}

export default function ConfirmDialog({
  isOpen,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  onConfirm,
  onCancel,
  isDanger = false
}: ConfirmDialogProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop Overlay */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.5 }}
            exit={{ opacity: 0 }}
            onClick={onCancel}
            className="fixed inset-0 z-50 bg-black/60 backdrop-blur-2xs"
          />

          {/* Modal Container */}
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ scale: 0.95, opacity: 0, y: 15 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.95, opacity: 0, y: 15 }}
              transition={{ type: 'spring', damping: 25, stiffness: 350 }}
              className="w-full max-w-sm rounded-2xl border border-gray-150 bg-white p-5 shadow-xl dark:border-gray-800 dark:bg-gray-900"
            >
              <div className="flex items-start space-x-3">
                <div
                  className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${
                    isDanger
                      ? 'bg-red-50 text-red-500 dark:bg-red-950/20 dark:text-red-400'
                      : 'bg-indigo-50 text-indigo-500 dark:bg-indigo-950/20 dark:text-indigo-400'
                  }`}
                >
                  <LucideIcon name={isDanger ? 'Flame' : 'Sparkles'} size={18} className={isDanger ? 'rotate-180' : ''} />
                </div>
                <div className="min-w-0 flex-1">
                  <h3 className="font-display text-sm font-bold text-gray-900 dark:text-gray-100">
                    {title}
                  </h3>
                  <p className="mt-1 text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                    {message}
                  </p>
                </div>
              </div>

              <div className="mt-5 flex items-center justify-end space-x-2">
                <button
                  type="button"
                  onClick={onCancel}
                  className="rounded-xl px-4 py-2 text-xs font-semibold text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800 transition"
                >
                  {cancelText}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    onConfirm();
                  }}
                  className={`rounded-xl px-5 py-2 text-xs font-bold text-white shadow-xs transition ${
                    isDanger
                      ? 'bg-red-600 hover:bg-red-700'
                      : 'bg-indigo-600 hover:bg-indigo-700'
                  }`}
                >
                  {confirmText}
                </button>
              </div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}
