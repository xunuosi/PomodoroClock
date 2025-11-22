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

// 使用 V2 装饰器修饰类，实现深度观测
@ObservedV2
export class TimerStore {
  @Trace currentMode: TimerMode = TimerMode.Focus;
  @Trace timeLeft: number = 25 * 60;
  @Trace totalTime: number = 25 * 60;
  @Trace isRunning: boolean = false;
  // ✅ [修改] 将 string[] 改为 TaskItem[]
  @Trace taskList: TaskItem[] = [];

  private timerId: number = -1;

  // 切换模式
  switchMode(mode: TimerMode) {
    this.stopTimer();
    this.currentMode = mode;
    this.isRunning = false;

    if (mode === TimerMode.Focus) {
      this.totalTime = 25 * 60;
    } else if (mode === TimerMode.Short) {
      this.totalTime = 5 * 60;
    } else {
      this.totalTime = 15 * 60;
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
          this.stopTimer();
          this.isRunning = false;
          promptAction.showToast({ message: 'Time is up!' });
        }
      }, 1000);
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