import { promptAction } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 定义计时模式枚举
export enum TimerMode {
  Focus = 'Focus',
  Short = 'Short_rest',
  Long = 'Long_rest'
}

class TaskDTO {
  id: number = 0;
  content: string = '';
  isCompleted: boolean = false;
}

class SettingsDTO {
  focusDuration: number = 25;
  shortBreakDuration: number = 5;
  longBreakDuration: number = 15;
  autoStartBreaks: boolean = false;
  autoStartFocus: boolean = false;
  longBreakInterval: number = 4;
  notificationEnabled: boolean = true;
}

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

  copyFrom(other: SettingsModel) {
    this.focusDuration = other.focusDuration;
    this.shortBreakDuration = other.shortBreakDuration;
    this.longBreakDuration = other.longBreakDuration;
    this.autoStartBreaks = other.autoStartBreaks;
    this.autoStartFocus = other.autoStartFocus;
    this.longBreakInterval = other.longBreakInterval;
    this.notificationEnabled = other.notificationEnabled;
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

  @Trace settings: SettingsModel = new SettingsModel();
  @Trace completedPomodoros: number = 0; // 当前循环已完成的专注次数

  private timerId: number = -1;
  private pref: preferences.Preferences | null = null;

  // 初始化并加载数据 (需要在 UIAbility 或 Page 的 aboutToAppear 中调用)
  async initData(context: common.Context) {
    try {
      // 1. 获取首选项实例
      this.pref = await preferences.getPreferences(context, 'PomodoroStore');

      // 2. 加载任务列表
      const tasksJson = await this.pref.get('taskList', '[]') as string;
      const loadedTasks = JSON.parse(tasksJson) as TaskItem[];
      // 重新映射为 TaskItem 实例以确保 @ObservedV2 生效 (如果是纯对象数组可能失去响应性，最好重新 new)
      // 但在 V2 中，只要数组替换，且元素结构一致通常没问题。为了稳妥：
      this.taskList = loadedTasks.map(t => {
        let item = new TaskItem(t.content);
        item.id = t.id;
        item.isCompleted = t.isCompleted;
        return item;
      });

      // 3. 加载设置
      const settingsJson = await this.pref.get('settings', '') as string;
      if (settingsJson) {
        const savedSettings = JSON.parse(settingsJson) as SettingsModel;
        // 逐个赋值以保持响应性
        this.settings.focusDuration = savedSettings.focusDuration;
        this.settings.shortBreakDuration = savedSettings.shortBreakDuration;
        this.settings.longBreakDuration = savedSettings.longBreakDuration;
        this.settings.autoStartBreaks = savedSettings.autoStartBreaks;
        this.settings.autoStartFocus = savedSettings.autoStartFocus;
        this.settings.longBreakInterval = savedSettings.longBreakInterval;
        this.settings.notificationEnabled = savedSettings.notificationEnabled;
      }

      // 4. 初始化时间 (如果之前保存了状态，也可以恢复，这里暂时重置为配置时长)
      this.resetTimer();

    } catch (err) {
      console.error('Failed to load data:', JSON.stringify(err));
    }
  }

  // 保存数据到磁盘
  saveData() {
    if (!this.pref) return;
    try {
      // ✅ 修复：显式指定映射后的类型为 TaskDTO[]
      const plainTasks: TaskDTO[] = this.taskList.map((task) => {
        // 显式声明对象字面量的类型
        const item: TaskDTO = {
          id: task.id,
          content: task.content,
          isCompleted: task.isCompleted
        };
        return item;
      });
      const tasksJson = JSON.stringify(plainTasks);

      // ✅ 修复：显式指定类型为 SettingsDTO
      const plainSettings: SettingsDTO = {
        focusDuration: this.settings.focusDuration,
        shortBreakDuration: this.settings.shortBreakDuration,
        longBreakDuration: this.settings.longBreakDuration,
        autoStartBreaks: this.settings.autoStartBreaks,
        autoStartFocus: this.settings.autoStartFocus,
        longBreakInterval: this.settings.longBreakInterval,
        notificationEnabled: this.settings.notificationEnabled
      };
      const settingsJson = JSON.stringify(plainSettings);

      // 写入首选项
      this.pref.put('taskList', tasksJson);
      this.pref.put('settings', settingsJson);
      this.pref.flush(); // 刷盘
    } catch (err) {
      console.error('Failed to save data:', JSON.stringify(err));
    }
  }

  // 切换模式
  switchMode(mode: TimerMode) {
    this.stopTimer();
    this.currentMode = mode;
    this.isRunning = false;

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
      this.saveData();
    }
  }

  toggleTask(task: TaskItem) {
    task.isCompleted = !task.isCompleted;
    this.saveData();
  }

  deleteTask(task: TaskItem) {
    const index = this.taskList.indexOf(task);
    if (index !== -1) {
      this.taskList.splice(index, 1);
      this.saveData();
    }
  }

  // 格式化时间
  get formattedTime(): string {
    const m = Math.floor(this.timeLeft / 60).toString().padStart(2, '0');
    const s = (this.timeLeft % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }
}