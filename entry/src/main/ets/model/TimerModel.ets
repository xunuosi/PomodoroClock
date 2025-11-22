import { promptAction } from '@kit.ArkUI';

// 定义计时模式枚举
export enum TimerMode {
  Focus = 'Focus',
  Short = 'Short_rest',
  Long = 'Long_rest'
}

// ✅ [新增] 定义任务项类，使用 V2 装饰器确保 UI 能监听到属性变化
@ObservedV2
export class TaskItem {
  id: number;
  @Trace content: string;
  @Trace isCompleted: boolean;

  constructor(content: string) {
    this.id = Date.now() + Math.random(); // 生成唯一ID
    this.content = content;
    this.isCompleted = false;
  }
}

@ObservedV2
export class SettingsModel {
  @Trace focusDuration: number = 25;      // 专注时长 (分钟)
  @Trace shortBreakDuration: number = 5;  // 短休息时长 (分钟)
  @Trace longBreakDuration: number = 15;  // 长休息时长 (分钟)

  @Trace autoStartBreaks: boolean = false;   // 自动开始休息
  @Trace autoStartFocus: boolean = false;    // 自动开始专注
  @Trace longBreakInterval: number = 4;      // 长休息间隔 (几个番茄后)

  @Trace notificationEnabled: boolean = true; // 计时结束提醒
}

// 使用 V2 装饰器修饰类，实现深度观测
@ObservedV2
export class TimerStore {
  @Trace currentMode: TimerMode = TimerMode.Focus;
  @Trace timeLeft: number = 25 * 60;
  @Trace totalTime: number = 25 * 60;
  @Trace isRunning: boolean = false;
  // ✅ [修改] 将 string[] 改为 TaskItem[]
  @Trace taskList: TaskItem[] = [];

  @Trace settings: SettingsModel = new SettingsModel();
  @Trace completedPomodoros: number = 0; // 当前循环已完成的专注次数

  private timerId: number = -1;

  // 切换模式
  switchMode(mode: TimerMode) {
    this.stopTimer();
    this.currentMode = mode;
    this.isRunning = false;

    // ✅ 从配置中读取时长
    if (mode === TimerMode.Focus) {
      this.totalTime = this.settings.focusDuration * 60;
    } else if (mode === TimerMode.Short) {
      this.totalTime = this.settings.shortBreakDuration * 60;
    } else {
      this.totalTime = this.settings.longBreakDuration * 60;
    }
    this.timeLeft = this.totalTime;
  }

  // 开始/暂停
  toggleTimer() {
    if (this.isRunning) {
      this.stopTimer();
      this.isRunning = false;
    } else {
      this.isRunning = true;
      this.timerId = setInterval(() => {
        if (this.timeLeft > 0) {
          this.timeLeft--;
        } else {
          // 🛑 倒计时结束逻辑
          this.handleTimerComplete();
        }
      }, 1000);
    }
  }

  private handleTimerComplete() {
    this.stopTimer();
    this.isRunning = false;

    // 1. 提醒 (声音/震动)
    if (this.settings.notificationEnabled) {
      promptAction.showToast({ message: '⏰ 计时结束！' });
      // 这里可以后续接入 AVPlayer 播放音效或 Vibrator 震动
    }

    // 2. 自动化流转逻辑
    if (this.currentMode === TimerMode.Focus) {
      // --- 专注结束 ---
      this.completedPomodoros++;

      // 判断是否达到长休息间隔
      if (this.completedPomodoros % this.settings.longBreakInterval === 0) {
        this.switchMode(TimerMode.Long);
      } else {
        this.switchMode(TimerMode.Short);
      }

      // 自动开始休息？
      if (this.settings.autoStartBreaks) {
        this.toggleTimer();
      }

    } else {
      // --- 休息结束 (无论是短还是长) ---
      this.switchMode(TimerMode.Focus);

      // 自动开始专注？
      if (this.settings.autoStartFocus) {
        this.toggleTimer();
      }
    }
  }

  stopTimer() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  get completedTaskCount(): number {
    // 过滤出 isCompleted 为 true 的任务并计算长度
    return this.taskList.filter(task => task.isCompleted).length;
  }

  resetTimer() {
    this.stopTimer();
    this.isRunning = false;
    this.timeLeft = this.totalTime;
  }

  addTask(taskName: string) {
    if (taskName.trim() !== '') {
      this.taskList.push(new TaskItem(taskName));
    }
  }

  toggleTask(task: TaskItem) {
    task.isCompleted = !task.isCompleted;
  }

  deleteTask(task: TaskItem) {
    const index = this.taskList.indexOf(task);
    if (index !== -1) {
      this.taskList.splice(index, 1);
    }
  }

  // 格式化时间
  get formattedTime(): string {
    const m = Math.floor(this.timeLeft / 60).toString().padStart(2, '0');
    const s = (this.timeLeft % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }
}