// ets/model/Types.ets

export enum TimerMode {
  FOCUS = 'FOCUS',
  SHORT_BREAK = 'SHORT_BREAK',
  LONG_BREAK = 'LONG_BREAK',
}

export enum AppView {
  TIMER = 'TIMER',
  TASKS = 'TASKS',
  STATS = 'STATS',
  SETTINGS = 'SETTINGS',
}

@Observed
export class Task {
  id: string;
  title: string;
  completed: boolean;
  estimatedPomodoros: number;
  completedPomodoros: number;

  constructor(title: string, est: number) {
    this.id = new Date().getTime().toString();
    this.title = title;
    this.completed = false;
    this.estimatedPomodoros = est;
    this.completedPomodoros = 0;
  }
}

export class Settings {
  focusDuration: number = 25;
  shortBreakDuration: number = 5;
  longBreakDuration: number = 15;
  autoStartBreaks: boolean = false;
  autoStartPomodoros: boolean = false;
  themeColor: string = 'red';
}

export class DailyStat {
  day: string;
  minutes: number;

  constructor(day: string, minutes: number) {
    this.day = day;
    this.minutes = minutes;
  }
}

export class PointHistoryItem {
  id: string;
  reason: string;
  amount: number;
  timestamp: number;
  type: 'focus' | 'task' | 'bonus';

  constructor(reason: string, amount: number, type: 'focus' | 'task' | 'bonus') {
    this.id = new Date().getTime().toString() + Math.random();
    this.reason = reason;
    this.amount = amount;
    this.timestamp = new Date().getTime();
    this.type = type;
  }
}