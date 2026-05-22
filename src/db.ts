import { doc, collection, setDoc, getDoc, getDocs, deleteDoc, writeBatch } from 'firebase/firestore';
import { db } from './firebase';
import { Habit, HabitLog, Badge, AppSettings } from './types';

const clean = <T>(data: T): T => JSON.parse(JSON.stringify(data));

const habitsCol = (uid: string) => collection(db, 'users', uid, 'habits');
const logsCol = (uid: string) => collection(db, 'users', uid, 'logs');
const badgesCol = (uid: string) => collection(db, 'users', uid, 'badges');
const userDoc = (uid: string) => doc(db, 'users', uid);

export const saveHabit = (uid: string, habit: Habit) =>
  setDoc(doc(habitsCol(uid), habit.id), clean(habit));

export const saveLog = (uid: string, log: HabitLog) =>
  setDoc(doc(logsCol(uid), log.id), clean(log));

export const saveBadge = (uid: string, badge: Badge) =>
  setDoc(doc(badgesCol(uid), badge.id), clean(badge));

export const saveUserSettings = (uid: string, settings: AppSettings) =>
  setDoc(userDoc(uid), { settings: clean(settings) }, { merge: true });

export async function loadUserData(uid: string) {
  const [habitsSnap, logsSnap, badgesSnap, userSnap] = await Promise.all([
    getDocs(habitsCol(uid)),
    getDocs(logsCol(uid)),
    getDocs(badgesCol(uid)),
    getDoc(userDoc(uid)),
  ]);

  return {
    habits: habitsSnap.docs.map(d => d.data() as Habit),
    logs: logsSnap.docs.map(d => d.data() as HabitLog),
    badges: badgesSnap.docs.map(d => d.data() as Badge),
    settings: userSnap.exists() ? (userSnap.data()?.settings as AppSettings | undefined) : undefined,
  };
}

export async function saveAllData(uid: string, habits: Habit[], logs: HabitLog[], badges: Badge[]) {
  const allDocs = [
    ...habits.map(h => ({ col: habitsCol(uid), id: h.id, data: clean(h) })),
    ...logs.map(l => ({ col: logsCol(uid), id: l.id, data: clean(l) })),
    ...badges.map(b => ({ col: badgesCol(uid), id: b.id, data: clean(b) })),
  ];

  for (let i = 0; i < allDocs.length; i += 499) {
    const batch = writeBatch(db);
    allDocs.slice(i, i + 499).forEach(({ col, id, data }) => {
      batch.set(doc(col, id), data);
    });
    await batch.commit();
  }
}

export async function clearUserData(uid: string) {
  const [habitsSnap, logsSnap, badgesSnap] = await Promise.all([
    getDocs(habitsCol(uid)),
    getDocs(logsCol(uid)),
    getDocs(badgesCol(uid)),
  ]);

  const allDocs = [...habitsSnap.docs, ...logsSnap.docs, ...badgesSnap.docs];
  for (let i = 0; i < allDocs.length; i += 499) {
    const batch = writeBatch(db);
    allDocs.slice(i, i + 499).forEach(d => batch.delete(d.ref));
    await batch.commit();
  }

  await deleteDoc(userDoc(uid));
}
