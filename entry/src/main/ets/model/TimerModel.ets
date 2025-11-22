import { promptAction } from '@kit.ArkUI';

// 定义计时模式枚举
export enum TimerMode {
  Focus = 'Focus',
  Short = 'Short',
  Long = 'Long'
}

// 使用 V2 装饰器修饰类，实现深度观测
@ObservedV2
export class TimerStore {
  @Trace currentMode: TimerMode = TimerMode.Focus;
  @Trace timeLeft: number = 25 * 60;
  @Trace totalTime: number = 25 * 60;
  @Trace isRunning: boolean = false;
  @Trace taskList: string[] = [];

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

  resetTimer() {
    this.stopTimer();
    this.isRunning = false;
    this.timeLeft = this.totalTime;
  }

  addTask(taskName: string) {
    if (taskName.trim() !== '') {
      // V2 中直接 push 即可触发 UI 更新
      this.taskList.push(taskName);
    }
  }

  // 格式化时间
  get formattedTime(): string {
    const m = Math.floor(this.timeLeft / 60).toString().padStart(2, '0');
    const s = (this.timeLeft % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }
}