// src/main/ets/pages/Index.ets

// 预设时间（秒）
const POMODORO_DURATION: number = 25 * 60; // 25 分钟
const REST_DURATION: number = 5 * 60; // 5 分钟

@Entry
@Component
struct Index {
  // ---------------------------------
  // 1. 状态变量
  // ---------------------------------

  // @State 装饰的变量，当它们改变时，UI 会自动更新
  @State remainingSeconds: number = POMODORO_DURATION;
  @State isRunning: boolean = false;
  @State isRestPeriod: boolean = false; // 是否是休息时间

  // 计时器的 ID，用于清除计时器
  private timerId: number = -1;

  // ---------------------------------
  // 2. 核心逻辑方法
  // ---------------------------------

  /**
   * 启动计时器
   */
  startTimer(): void {
    if (this.isRunning) return; // 防止重复启动

    this.isRunning = true;
    // 每 1000 毫秒（1秒）执行一次
    this.timerId = setInterval(() => {
      if (this.remainingSeconds > 0) {
        this.remainingSeconds--;
      } else {
        // 时间到！
        this.stopTimer();
        this.handleTimerEnd();
      }
    }, 1000);
  }

  /**
   * 暂停计时器
   */
  pauseTimer(): void {
    if (!this.isRunning) return; // 只有在运行时才暂停
    this.isRunning = false;
    clearInterval(this.timerId); // 清除定时器
    this.timerId = -1;
  }

  /**
   * 停止计时器（内部调用）
   */
  private stopTimer(): void {
    this.isRunning = false;
    clearInterval(this.timerId);
    this.timerId = -1;
  }

  /**
   * 重置计时器
   * 重置为当前阶段（工作或休息）的初始时间
   */
  resetTimer(): void {
    this.stopTimer();
    this.remainingSeconds = this.isRestPeriod ? REST_DURATION : POMODORO_DURATION;
  }

  /**
   * 计时结束处理
   */
  handleTimerEnd(): void {
    // 播放提示音 (后续添加)
    console.info('Pomodoro: Time is up!');

    // 切换状态
    if (this.isRestPeriod) {
      // 休息结束 -> 切换到工作
      this.isRestPeriod = false;
      this.remainingSeconds = POMODORO_DURATION;
    } else {
      // 工作结束 -> 切换到休息
      this.isRestPeriod = true;
      this.remainingSeconds = REST_DURATION;
    }
    // 自动开始下一个阶段
    this.startTimer();
  }

  /**
   * 格式化时间，将秒转换为 MM:SS
   */
  formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSec = seconds % 60;
    // padStart(2, '0') 用于补零，例如 5 -> 05
    return `${minutes.toString().padStart(2, '0')}:${remainingSec.toString().padStart(2, '0')}`;
  }

  // ---------------------------------
  // 3. UI 界面构建
  // ---------------------------------
  build() {
    Column() {
      // 标题：显示当前状态
      Text(this.isRestPeriod ? '休息一下' : '专注中')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40 })

      // 环形进度条 (仪表盘)
      Gauge({
        value: this.remainingSeconds, // 当前值
        min: 0, // 最小值
        max: this.isRestPeriod ? REST_DURATION : POMODORO_DURATION,
      }) {
        Column() {
          Text(this.formatTime(this.remainingSeconds))
            .fontSize(50)
            .fontWeight(FontWeight.Medium)
        }.width('100%').height('100%')
      }
        .width('80%')
        .aspectRatio(1) // 保持宽高比为 1:1 (正方形)
        .margin({ top: 30, bottom: 30 })
        .colors([
          // 设置渐变色
          [$r('app.color.start_color'), 0], // 使用资源文件中的颜色
          [$r('app.color.end_color'), 1]
        ])
        .strokeWidth(20) // 进度条宽度

      // 控制按钮行
      Row({ space: 20 }) { // space 20 按钮间距
        // 开始/暂停 按钮
        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          // 根据 isRunning 状态显示不同文本
          Text(this.isRunning ? '暂 停' : '开 始')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }
        .width(120)
        .height(50)
        .backgroundColor(this.isRunning ? $r('app.color.pause_button') : $r('app.color.start_button'))
        .onClick(() => {
          if (this.isRunning) {
            this.pauseTimer();
          } else {
            this.startTimer();
          }
        })

        // 重置按钮
        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Text('重 置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }
        .width(120)
        .height(50)
        .backgroundColor($r('app.color.reset_button'))
        .onClick(() => {
          this.resetTimer();
        })
      }
      .margin({ bottom: 40 })

    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween) // 垂直方向上均匀分布
    .alignItems(HorizontalAlign.Center) // 水平居中
  }
}