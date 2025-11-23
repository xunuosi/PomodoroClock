import { UIContext } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';


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
  private uiContext: UIContext | null = null;

  // 初始化并加载数据 (需要在 UIAbility 或 Page 的 aboutToAppear 中调用)
  async initData(uiContext: UIContext) {
    try {
      this.uiContext = uiContext; // 保存 UIContext
      // 通过 UIContext 获取 HostContext (UIAbilityContext) 用于首选项
      const context = uiContext.getHostContext() as common.UIAbilityContext;
      // 获取实例
      this.pref = await preferences.getPreferences(context, 'PomodoroStore');

      // 1. 加载设置
      const settingsJson = await this.pref.get('settings', '') as string;
      if (settingsJson && settingsJson.length > 0) {
        // ✅ 使用 try-catch 包裹解析过程，防止烂数据导致崩溃
        try {
          const saved = JSON.parse(settingsJson) as SettingsDTO;
          // ✅ 逐个赋值，并提供兜底默认值
          this.settings.focusDuration = saved.focusDuration ?? 25;
          this.settings.shortBreakDuration = saved.shortBreakDuration ?? 5;
          this.settings.longBreakDuration = saved.longBreakDuration ?? 15;
          this.settings.autoStartBreaks = saved.autoStartBreaks ?? false;
          this.settings.autoStartFocus = saved.autoStartFocus ?? false;
          this.settings.longBreakInterval = saved.longBreakInterval ?? 4;
          this.settings.notificationEnabled = saved.notificationEnabled ?? true;
        } catch (e) {
          console.error('Error parsing settings JSON:', e);
        }
      }

      // 2. 加载任务
      const tasksJson = await this.pref.get('taskList', '[]') as string;
      if (tasksJson) {
        try {
          const loadedTasks = JSON.parse(tasksJson) as TaskDTO[];
          this.taskList = loadedTasks.map(t => {
            let item = new TaskItem(t.content);
            item.id = t.id;
            item.isCompleted = t.isCompleted;
            return item;
          });
        } catch (e) {
          console.error('Error parsing tasks JSON:', e);
        }
      }

      // ✅ 数据加载完成后，立即重置计时器以应用最新配置
      this.resetTimer();

    } catch (err) {
      console.error('Failed to init preferences:', JSON.stringify(err));
    }
  }

  // 保存数据到磁盘
  saveData() {
    if (!this.pref) return;
    try {
      // 1. 序列化设置
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

      // 2. 序列化任务
      const plainTasks: TaskDTO[] = this.taskList.map((task) => {
        let item = new TaskDTO();
        item.id = task.id;
        item.content = task.content;
        item.isCompleted = task.isCompleted;
        return item;
      });
      const tasksJson = JSON.stringify(plainTasks);

      // 3. 写入并刷盘
      this.pref.put('settings', settingsJson);
      this.pref.put('taskList', tasksJson);
      this.pref.flush(); // 确保写入磁盘

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
      // ✅ 修改：使用 uiContext 调用 showToast
      if (this.uiContext) {
        this.uiContext.getPromptAction().showToast({ message: '⏰ 计时结束！' });
      }

      this.triggerFeedback();
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

  // 触发反馈（震动 + 通知）
  private async triggerFeedback() {
    // 1. 触发震动 (持续 1 秒)
    try {
      // 检查设备是否支持震动
      vibrator.startVibration({
        type: 'time',
        duration: 1000, // 震动时长 1000ms
      }, {
        id: 0,
        usage: 'alarm' // 用途：闹钟/提醒
      }, (error: BusinessError) => {
        if (error) {
          console.error(`Vibration failed, code: ${error.code}, message: ${error.message}`);
        }
      });
    } catch (err) {
      console.error('Vibration error:', JSON.stringify(err));
    }
    // 1. 定义默认文案 (兜底用)
    let title = '通知';
    let text = '计时结束';
    let additionalInfo = 'Tomatodo';

    if (this.uiContext) {
      try {
        const context = this.uiContext.getHostContext() as common.UIAbilityContext;
        const resMgr = context.resourceManager;

        if (this.currentMode === TimerMode.Focus) {
          title = resMgr.getStringSync($r('app.string.notify_focus_title'));
          text = resMgr.getStringSync($r('app.string.notify_focus_text'));
        } else {
          title = resMgr.getStringSync($r('app.string.notify_rest_title'));
          text = resMgr.getStringSync($r('app.string.notify_rest_text'));
        }

        // 获取应用名
        additionalInfo = resMgr.getStringSync($r('app.string.app_name'));

      } catch (e) {
        console.error('Failed to get string resource:', JSON.stringify(e));
      }
    }

    const notificationRequest: notificationManager.NotificationRequest = {
      id: 1001, // 通知ID
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: text,
          additionalText: additionalInfo
        }
      },
    };

    try {
      await notificationManager.publish(notificationRequest);
    } catch (err) {
      console.error(`Notification failed, code: ${err.code}, message: ${err.message}`);
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
    this.switchMode(this.currentMode);
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